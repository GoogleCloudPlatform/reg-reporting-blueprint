import argparse
import datetime as dt
import numpy as np
import pandas as pd


params = {'random_seed': 1,  # help generate consistent set of randomized data
          'start_price': 5,
          'nbbo_mid_drift': 0,
          'nbbo_mid_std': 0.001,
          'nbbo_spread_mean': 0.02,
          'nbbo_spread_std': 0.01,
          'size_poisson_lambda': 2,
          'nbbo_timestamp_noise_ms': 100,
          'order_arrival_exp_p_value': 0.1,
          'order_arrival_exp_scale': 50,
          'flashing_span_min_ms': 100,
          'flashing_span_max_ms': 500,
          'normal_span_min': 10,
          'normal_span_max': 100,
          'exchange_delay_min_ms': 5,
          'exchange_delay_max_ms': 20}


def generate(date_str: str, symbol: str, output_dir: str) -> None:
    num_of_points = 23401
    np.random.seed(params['random_seed'])
    trade_date = dt.datetime.strptime(date_str, '%Y-%m-%d').date()
    market_open_time = dt.datetime(trade_date.year, trade_date.month, trade_date.day, 9, 30, 0, 0)

    exchange_delay_pool = np.random.uniform(params['exchange_delay_min_ms'], params['exchange_delay_max_ms'], 5001)
    global_delay_num = 0

    # NBBO
    md_table = pd.DataFrame(columns=['trade_date', 'timestamp', 'symbol', 'bid', 'bid_size', 'ask', 'ask_size'])

    # Generate GBM mid-price
    returns = np.random.normal(loc=params['nbbo_mid_drift'], scale=params['nbbo_mid_std'], size=num_of_points)
    price = params['start_price'] * (1 + returns).cumprod()
    spread = np.random.normal(loc=params['nbbo_spread_mean'], scale=params['nbbo_spread_std'], size=num_of_points)

    # Derive bid/ask from the mid price and spread
    md_table['bid'] = np.round(price - spread / 2, decimals=2)
    md_table['ask'] = np.round(price + spread / 2, decimals=2)
    md_table['bid_size'] = (np.random.poisson(params['size_poisson_lambda'], num_of_points) + 1) * 100
    md_table['ask_size'] = (np.random.poisson(params['size_poisson_lambda'], num_of_points) + 1) * 100

    # NBBO timestamp is every round second +/- noise in milliseconds
    md_table['trade_date'] = trade_date
    time_noise = np.random.normal(loc=0, scale=params['nbbo_timestamp_noise_ms'], size=num_of_points)
    time_list = [market_open_time + dt.timedelta(seconds=i, milliseconds=int(time_noise[i]))
                 for i in range(num_of_points)]
    md_table['timestamp'] = time_list

    md_table['symbol'] = symbol

    # Order events
    sent_table = pd.DataFrame(columns=['trade_date', 'timestamp', 'trading_model', 'account', 'order_id', 'event',
                                       'symbol', 'side', 'size', 'price', 'tif', 'fill_size', 'fill_price'])

    # Random arrival of order creations by exponential distribution
    order_time_sec = list((np.random.exponential(params['order_arrival_exp_p_value'], 10000) *
                           params['order_arrival_exp_scale']).cumsum())
    order_time_sec = [x for x in order_time_sec if x < 23400]
    order_num = len(order_time_sec)

    order_time = [market_open_time + dt.timedelta(seconds=i, microseconds=0) for i in order_time_sec]
    sent_table['timestamp'] = order_time
    sent_table['side'] = np.random.choice(a=['Buy', 'Sell'], size=order_num)
    sent_table['size'] = (np.random.poisson(params['size_poisson_lambda'], order_num) + 1) * 100
    sent_table['event'] = 'Sent'

    sent_table['order_id'] = [f'Order_{symbol}_{x + 1}' for x in sent_table.index]
    sent_table['trade_date'] = trade_date
    sent_table['symbol'] = symbol

    slim_md = md_table[['timestamp', 'bid', 'ask']]
    sent_table = pd.merge_asof(sent_table, slim_md, on='timestamp')

    ol_table = pd.DataFrame(columns=['trade_date', 'timestamp', 'trading_model', 'account', 'order_id', 'event',
                                     'symbol', 'exchange', 'side', 'size', 'price', 'tif', 'prev_size', 'prev_price',
                                     'fill_size', 'fill_price', 'exec_id'])
    exec_id_counter = 1
    # Create the following events for each orders sent
    for _, row in sent_table.iterrows():
        d = row.to_dict()

        d['exchange'] = np.random.choice(a=['NYSE', 'NASDAQ', 'BATS', 'ARCA'], p=[0.3, 0.4, 0.2, 0.1])
        d['tif'] = np.random.choice(a=['Day', 'IOC'], p=[0.5, 0.5])
        if d['tif'] == 'IOC':
            outcome = np.random.choice(a=['flashCancel', 'fill'], p=[0.5, 0.5])
        else:
            outcome = np.random.choice(a=['normalCancel', 'normalReplace', 'flashCancel', 'flashReplace', 'fill'],
                                       p=[0.5, 0.1, 0.1, 0.1, 0.2])

        if outcome == 'fill':
            d['price'] = d['ask'] if d['side'] == 'Buy' else d['bid']
            ol_table = ol_table.append(d, ignore_index=True)
        else:
            d['price'] = d['bid'] if d['side'] == 'Buy' else d['ask']
            ol_table = ol_table.append(d, ignore_index=True)

        # Assume all orders are ack-ed
        d['timestamp'] += dt.timedelta(milliseconds=exchange_delay_pool[global_delay_num])
        global_delay_num = (global_delay_num + 1) % 5000
        d['event'] = 'Acknowledged'
        ol_table = ol_table.append(d, ignore_index=True)

        if outcome != 'fill':
            # Immediate cancel of IOC orders
            if d['tif'] == 'IOC':
                d['timestamp'] += dt.timedelta(milliseconds=exchange_delay_pool[global_delay_num])
                global_delay_num = (global_delay_num + 1) % 5000
                d['event'] = 'Canceled'
                ol_table = ol_table.append(d, ignore_index=True)
                continue

            # Day order: random arrival of cancel/replace, with possibility of flash cancel/replace
            if 'normal' in outcome:
                interval = np.random.uniform(params['normal_span_min'], params['normal_span_max'])
                d['timestamp'] += dt.timedelta(seconds=interval)
            else:
                interval_ms = np.random.uniform(params['flashing_span_min_ms'], params['flashing_span_max_ms'])
                d['timestamp'] += dt.timedelta(milliseconds=interval_ms)

            d['event'] = 'CancelSent' if 'Cancel' in outcome else 'ReplaceSent'
            ol_table = ol_table.append(d, ignore_index=True)
            d['timestamp'] += dt.timedelta(milliseconds=exchange_delay_pool[global_delay_num])
            global_delay_num = (global_delay_num + 1) % 5000
            d['event'] = 'Canceled' if 'Cancel' in outcome else 'Replaced'
            if 'Replace' in outcome:
                d['prev_price'] = d['price']
                d['prev_size'] = str(int(d['size']))
                if np.random.randint(0, 1) == 0:
                    d['price'] += 0.01
                else:
                    d['size'] = str(int(d['size'] + 100))
            ol_table = ol_table.append(d, ignore_index=True)
        else:
            # order filled
            if d['tif'] == 'IOC':
                d['timestamp'] += dt.timedelta(milliseconds=exchange_delay_pool[global_delay_num])
                global_delay_num = (global_delay_num + 1) % 5000
            else:
                d['timestamp'] += dt.timedelta(seconds=np.random.uniform(1, 30))
            d['event'] = 'Filled'
            d['fill_size'] = '100'
            d['fill_price'] = d['price']
            d['exec_id'] = f'Exec_id_{exec_id_counter}'
            exec_id_counter += 1
            ol_table = ol_table.append(d, ignore_index=True)

    ol_table = ol_table.drop(columns=['ask', 'bid']).sort_values(by=['timestamp'])
    ol_table['trading_model'] = 'Strategy_A'
    ol_table['account'] = 'Account_123'

    ol_table.to_csv(f'{output_dir}/orders_log_{date_str}_{symbol}.csv', index=False)
    md_table.to_csv(f'{output_dir}/market_data_{date_str}_{symbol}.csv', index=False)


def main():
    parser = argparse.ArgumentParser(description='Generate randomized OL/MD')
    parser.add_argument('-d',
                        '--date',
                        required=True)
    parser.add_argument('-s',
                        '--symbol',
                        required=True)
    parser.add_argument('-o',
                        '--output_dir',
                        metavar='<PATH>',
                        help='Path to write output data files',
                        default='.')
    args = parser.parse_args()

    generate(args.date, args.symbol, args.output_dir)


if __name__ == '__main__':
    main()

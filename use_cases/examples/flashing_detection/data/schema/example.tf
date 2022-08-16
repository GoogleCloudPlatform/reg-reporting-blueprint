provider "google" {
  project     = var.PROJECT_ID
  region      = var.REGION_NAME
}

resource "google_bigquery_dataset" "market_data" {
  dataset_id                  = var.MARKET_DATA_DATASET
  description                 = "This the dataset holds exchange disseminated public market data (NBBO)."
  location                    = "US"
}

resource "google_bigquery_table" "nbbo" {
  table_id = "nbbo"
  dataset_id = google_bigquery_dataset.market_data.dataset_id
  schema = <<EOF
[
    {
      "description": "trade date",
      "mode": "REQUIRED",
      "name": "trade_date",
      "type": "DATE"
    },
    {
      "description": "NBBO update timestamp (microsecond resolution)",
      "mode": "REQUIRED",
      "name": "timestamp",
      "type": "DATETIME"
    },
    {
      "description": "company's stock ticker",
      "mode": "REQUIRED",
      "name": "symbol",
      "type": "STRING"
    },
    {
      "description": "best bid price (best price someone is willing to buy the stock for)",
      "mode": "REQUIRED",
      "name": "bid",
      "type": "FLOAT"
    },
    {
      "description": "number of shares offered to buy at best bid price",
      "mode": "REQUIRED",
      "name": "bid_size",
      "type": "INTEGER"
    },
    {
      "description": "best ask price (best price someone is willing to sell the stock for)",
      "mode": "REQUIRED",
      "name": "ask",
      "type": "FLOAT"
    },
    {
      "description": "number of shares offered to sell at best ask price",
      "mode": "REQUIRED",
      "name": "ask_size",
      "type": "INTEGER"
    }
]
EOF
}

resource "google_bigquery_dataset" "order_data" {
  dataset_id                  = var.ORDER_DATA_DATASET
  description                 = "This is a dataset for your proprietary order data."
  location                    = "US"
}

resource "google_bigquery_table" "orders" {
  table_id = "orders"
  dataset_id = google_bigquery_dataset.order_data.dataset_id
  schema = <<EOF
[
    {
      "description": "trade date",
      "mode": "REQUIRED",
      "name": "trade_date",
      "type": "DATE"
    },
    {
      "description": "order event timestamp (microsecond resolution)",
      "mode": "REQUIRED",
      "name": "timestamp",
      "type": "DATETIME"
    },
    {
      "description": "trading strategy name or identifier",
      "mode": "REQUIRED",
      "name": "trading_model",
      "type": "STRING"
    },
    {
      "description": "trading account",
      "mode": "REQUIRED",
      "name": "account",
      "type": "STRING"
    },
    {
      "description": "unique order ID (only guaranteed to be unique per trade date)",
      "mode": "REQUIRED",
      "name": "order_id",
      "type": "STRING"
    },
    {
      "description": "order event. one of: Sent, Acknowledged, CancelSent, Canceled, ReplaceSent, Replaced, Filled",
      "mode": "REQUIRED",
      "name": "event",
      "type": "STRING"
    },
    {
      "description": "Financial instrument identifier (e.g. a company's stock ticker)",
      "mode": "REQUIRED",
      "name": "symbol",
      "type": "STRING"
    },
    {
      "description": "exchange the order was sent to. one of: ARCA, BATS, NASDAQ, NYSE",
      "mode": "REQUIRED",
      "name": "exchange",
      "type": "STRING"
    },
    {
      "description": "order side. one of: Buy, Sell",
      "mode": "REQUIRED",
      "name": "side",
      "type": "STRING"
    },
    {
      "description": "order size in shares",
      "mode": "REQUIRED",
      "name": "size",
      "type": "INTEGER"
    },
    {
      "description": "order price",
      "mode": "REQUIRED",
      "name": "price",
      "type": "FLOAT"
    },
    {
      "description": "time in force (maximal order lifespan). one of: Day, IOC (Immediate or Cancel)",
      "mode": "REQUIRED",
      "name": "tif",
      "type": "STRING"
    },
    {
      "description": "previous order size (if replaced)",
      "mode": "NULLABLE",
      "name": "prev_size",
      "type": "INTEGER"
    },
    {
      "description": "previous order price (if replaced)",
      "mode": "NULLABLE",
      "name": "prev_price",
      "type": "FLOAT"
    },
    {
      "description": "number of filled shares (if Filled event)",
      "mode": "NULLABLE",
      "name": "fill_size",
      "type": "INTEGER"
    },
    {
      "description": "trade price (if Filled event)",
      "mode": "NULLABLE",
      "name": "fill_price",
      "type": "FLOAT"
    },
    {
      "description": "exchange fill/execution ID (if Filled event)",
      "mode": "NULLABLE",
      "name": "exec_id",
      "type": "STRING"
    }
]
EOF
}

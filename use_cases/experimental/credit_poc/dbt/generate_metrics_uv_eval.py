#!/usr/bin/env python3
import os
import string
import json

model_template_string = """
{{
    config(
        materialized='model',
        ml_config={
            'MODEL_TYPE': 'LOGISTIC_REG',
            'INPUT_LABEL_COLS': ['${label_name}'],
            'AUTO_CLASS_WEIGHTS': true,
            'EARLY_STOP': true,
            'LS_INIT_LEARN_RATE': 0.1,
            'ENABLE_GLOBAL_EXPLAIN': true,
            'CATEGORY_ENCODING_METHOD': 'DUMMY_ENCODING',
            'CALCULATE_P_VALUES': true
        }
    )
}}
select
    ${feature_name},
    ${label_name}
from
    ${dbt_model_ref}
"""


def get_metrics_list(model_name,  # model.credit_poc.submissions_pivoted
                     column_prefixes,
                     path_to_catalog="./target/catalog.json") -> []:
    """
    Inspects a DBT catalogue to retrieve all the metrics which need to be evaluated
    :param path_to_catalog: a relative path to a .json DBT catalog file
    :param model_name: the name of the model. This MUST be a node in the json catalog, for example 'model.credit_poc.submissions_pivoted'
    :param column_prefix: the prefix of the column name
    :return: an array of all the metrics matching the prefix in the model
    """
    f = open(path_to_catalog, "r")
    parsed_catalog = json.load(f)
    # Try to get the content of the node
    try:
        columns_list = parsed_catalog['nodes'][model_name]['columns']
    except KeyError:
        raise "Could not find the data. Did you specify a valid model in the catalog?"
    # Try to convert into an array of metric names
    try:
        metrics_list = []
        for c in columns_list:
            for prefix in column_prefixes:
                if c.startswith(prefix):
                    metrics_list.append(c)
    except KeyError:
        raise "The column does not seem of STRUCT type."
    print("Found {} features".format(len(metrics_list)))
    return metrics_list


def create_metrics_eval_models(lst_features: [], label_name, dbt_model_ref, path='./models/eval/'):
    """
    Generates one file for each metric in the lst_metrics.
    The file generated is a templated DBT model, which creates a BQML materialisation to evaluate a given metric.
    :param lst_features: an array of metrics names. They must be columns existing in the dbt_model_ref
    :param label_name: the name of the column to be used as label
    :param dbt_model_ref: a reference to the dbt model where the features are available
    :param path: the folder path where the files need to be created
    :return: none
    """
    model_template = string.Template(model_template_string)
    for feature in lst_features:
        file_name = os.path.join(path, "eval_" + feature.replace(".", "_") + ".sql")
        # Create a file
        f = open(file_name, "w")
        # Use the template to create a model for this metric
        file_content = model_template.substitute(feature_name=feature,
                                                 label_name=label_name,
                                                 dbt_model_ref=dbt_model_ref)
        print("Created file {}".format(file_name))
        f.write(file_content)


#TODO: create main with some parameters using proper arguments

features = get_metrics_list(path_to_catalog='target/catalog.json',
                            model_name='model.credit_poc.training_data',
                            column_prefixes=['metric_', 'ratio_', 'log_'])

create_metrics_eval_models(features,
                           label_name='will_default',
                           path='./models/01_data_analysis/uv_logistic/',
                           dbt_model_ref="{{ref('training_data')}}")


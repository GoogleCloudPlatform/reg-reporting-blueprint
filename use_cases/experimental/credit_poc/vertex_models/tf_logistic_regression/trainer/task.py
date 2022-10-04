import tensorflow as tf
from datetime import datetime
import os
import argparse
try:
    import trainer.model as mod
    from trainer.bigquery import BigQuery
except ModuleNotFoundError:
    print("\n\nTrying to import modules from local directory...\n\n")
    import model as mod
    from bigquery import BigQuery

# Helper function to save weights to a csv file
def save_weights(trained_model, log_dir, filename):
    """
    This functions saves the weights of a logistic regression model into a csv file, and in the tensorboard as well.
    :param trained_model: a trained logistic regression model
    :param log_dir: directory where the weights should be saved
    :param filename: the name of the file where the weights are saved
    :return: a dictionary of the weights
    """
    # Create a file writer for TensorBoard
    file_writer = tf.summary.create_file_writer(log_dir)
    # Get the weights from the trained model
    weights = list(trained_model.weights)[0].numpy()
    # Save them into a dictionary and into a file
    inputs_coefficients = {}
    # Save them into a dictionary and into a file
    with open(os.path.join(log_dir, filename), 'w') as f, file_writer.as_default():
        # Write the header
        f.write("{},{}\n".format("Feature", "Weight"))
        # Write the data
        for i, var in enumerate(list(trained_model.inputs)):
            inputs_coefficients[var.name] = float(weights[i])
            # Save to file
            f.write("{},{}\n".format(var.name, float(weights[i])))
            # Save to logs
            tf.summary.text("{} (weight)".format(var.name),
                            "{}".format(weights[i]),
                            step=int(max(model.history.epoch)) # Log as the final epoch
                            )
    # return the dictionary
    return inputs_coefficients


if __name__ == "__main__":
    # Create all arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--project-id', dest='project_id', required=True,
                      type=str, help='Project for running BigQuery queries')
    parser.add_argument('--table-id', dest='table_id', type=str,
                        help="""Fully qualified table to read data from, in the format [project].[dataset].[table]
    The table must contain:
    * the features to the model, in individual columns (i.e. no struct)
    * is_test_data: a boolean column indicating whether the data is test (otherwise is training)
    * will_default_1y: used as the actual label""")
    #parser.add_argument('--limit-rows', dest='limit_rows',
    #                    default=-1, type=int,
    #                    help='Number of rows to be read. Specify -1 for all the rows.')
    parser.add_argument('--model-dir', dest='model_dir',
                        default=os.getenv('AIP_MODEL_DIR'), type=str,
                        help='Model directory')
    #parser.add_argument('--lr', dest='lr',
    #                    default=1e-4, type=float,
    #                    help='Learning rate.')
    parser.add_argument('--epochs', dest='epochs',
                        default=100, type=int,
                        help='Number of epochs.')
    #parser.add_argument('--drop-na', dest='drop_na',
    #                    default=True, type=int,
    #                    help='Whether to drop NA values from the data')
    parser.add_argument('--tensorboard-log-dir', dest='tensorboard_log_dir',
                        default=os.getenv('AIP_TENSORBOARD_LOG_DIR'), type=str,
                        help='Log directory for TensorBoard instance'),
    parser.add_argument('--weights-file', dest='weights_file',
                        default='weights.csv', type=str,
                        help='Filename for the weights file'),
    parser.add_argument('--shortname', dest='shortname',
                        default='mv-tf-logistic', type=str,
                        help='A short name of the model, used to separate the logs and model artefacts'),
    parser.add_argument('--tensorboard', dest='tensorboard', type=str,
                        help='The name of the tensorboard to upload logs to, in the format projects/{}/locations/{}/tensorboards/{}'),
    parser.add_argument('--experiment-id', dest='experiment_id', type=str,
                        help='The name of the tensorboard experiment'),
    args = parser.parse_args()
    
    # Determine a unique ID for the model
    model_id = args.shortname + "/" + datetime.now().strftime("%Y%m%d/%H%M%S") 
    
    # Create a BigQuery client
    client = BigQuery(args.project_id)
  
    # Convert rows to a schema for Tensorflow
    schema = client.get_tf_schema(args.table_id, "column_name != 'is_test_data'")
  
    # Build model
    # The list of features come from the extract schemas (focused on the IQ_
    # columns in this case)
    model = mod.build_model(features = [feature for feature in schema.keys() if
                                        feature.startswith('metric_') or
                                        feature.startswith('log_') or
                                        feature.startswith('ratio_')
                                        ]) # TODO: should parametrise the prefixes
  
    def features_and_labels(features):
        label = features.pop('label')  # this is what we will train for
        return features, label
  
    train_df = client.read_tf_dataset(args.table_id, schema, 'is_test_data is False').map(features_and_labels)
    eval_df = client.read_tf_dataset(args.table_id, schema, 'is_test_data is True').map(features_and_labels)
  
    # Create tensorboard callback if required
    callbacks = []
    if args.tensorboard_log_dir:
        callbacks.append(tf.keras.callbacks.TensorBoard(
            log_dir=os.path.join(args.tensorboard_log_dir, model_id),
            histogram_freq=1,
            write_graph=True,
            update_freq='epoch',
            embeddings_freq=1
            )
        )
  
    # Fit (Train) the model
    #
    # This will actually load the data incrementally (in batches) for the
    # training.
    model.fit(train_df,
              validation_data=eval_df,
              epochs=args.epochs,
              callbacks=callbacks)
  
    # Save the model locally if required
    if args.model_dir:
        print("Saving the TF model in the folder {}...".format(args.model_dir))
        tf.saved_model.save(model, args.model_dir)
  
    # Save the weights if required
    if args.weights_file:
        print("Saving the TF model weights.")
        save_weights(model, args.model_dir, args.weights_file)
        
    if args.tensorboard:
        print("Uploading the logs from dir {} to instance {}".format(args.tensorboard_log_dir, args.tensorboard))
        os.system('tb-gcp-uploader --tensorboard_resource_name={} --logdir={} --experiment_name={} --one_shot=True'.format(
            args.tensorboard,
            args.tensorboard_log_dir,
            args.experiment_id
        ))
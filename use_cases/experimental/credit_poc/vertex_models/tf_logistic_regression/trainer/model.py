import tensorflow as tf


def build_model(features):
    # Define the inputs as a dict of Keras Inputs - this allows to specify the exact input columns to the model
    inputs = {}
    for k in features:
        inputs[k] = tf.keras.Input(shape=(1,), name=k)

    # Intermediate layer with concatenation of all the inputs into a single layer
    concatenated = tf.keras.layers.Concatenate()(inputs.values())

    # Normalise the variables
    normalised = tf.keras.layers.BatchNormalization()(concatenated)  # TODO: switch to normalization

    # Modify the output by adding a Dense layer - this implements the logistic regression
    output = tf.keras.layers.Dense(1,
                                   activation='sigmoid'
                                   # activation functions: https://keras.io/api/layers/activations/
                                   )(normalised)

    # Now express the model a function producing an output based on the given input
    model = tf.keras.Model(inputs=inputs, outputs=output, name='logistic_regression')

    # Train the tensorflow model, and include a callback for the TensorBoard
    model.compile(optimizer='adam', loss='mse', metrics=['AUC'])

    return model


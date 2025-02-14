#!/bin/bash

# Create a directory for the layer
mkdir -p lambda_layer/python

# Install psycopg2-binary into the layer directory
pip install psycopg2-binary -t lambda_layer/python

# Create a ZIP file of the layer
cd lambda_layer
zip -r ../lambda_layer.zip .
cd ..

# Clean up
rm -rf lambda_layer


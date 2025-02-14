# Build process for Lambda function and layer
resource "null_resource" "build_lambda" {
  triggers = {
    lambda_hash = filebase64sha256("db_setup.py")
    layer_hash  = filebase64sha256("create_lambda_layer.sh")
  }

  provisioner "local-exec" {
    command = <<EOT
    echo "Listing contents of the current directory:"
    ls -l
    zip db_setup.zip db_setup.py
    dos2unix create_lambda_layer.sh
    chmod +x create_lambda_layer.sh
    ./create_lambda_layer.sh
  EOT
  }
}

# Lambda function definition
resource "aws_lambda_function" "db_setup" {
  depends_on = [null_resource.build_lambda]
  filename         = "db_setup.zip"
  function_name    = "todo-app-db-setup"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "db_setup.handler"
  source_code_hash = filebase64sha256("db_setup.py")
  runtime          = "python3.9"
  timeout          = 30

  layers = [aws_lambda_layer_version.psycopg2.arn]

  environment {
    variables = {
      DB_HOST     = aws_db_instance.default.address
      DB_USER     = aws_db_instance.default.username
      DB_PASSWORD = "secure_password"
      DB_NAME     = aws_db_instance.default.db_name
    }
  }

  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.lambda.id]
  }
}

# Lambda layer definition
resource "aws_lambda_layer_version" "psycopg2" {
  depends_on = [null_resource.build_lambda]
  filename   = "lambda_layer.zip"
  layer_name = "psycopg2-layer"

  compatible_runtimes = ["python3.9"]
}


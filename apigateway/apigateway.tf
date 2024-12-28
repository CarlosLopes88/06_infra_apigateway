# API Gateway
resource "aws_api_gateway_rest_api" "order_system_api" {
  name        = "order-system-api"
  description = "API Gateway for Order System"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Authorizer do Cognito
resource "aws_api_gateway_authorizer" "cognito" {
  name          = "CognitoUserPoolAuthorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  provider_arns = ["arn:aws:cognito-idp:us-east-1:740588470221:userpool/us-east-1_lIOSvhX0Z"]
  identity_source = "method.request.header.Authorization"
}

# Recursos e métodos para /webhook
resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_rest_api.order_system_api.root_resource_id
  path_part   = "webhook"
}

# Recurso para /webhook/pagseguro
resource "aws_api_gateway_resource" "webhook_pagseguro" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_resource.webhook.id
  path_part   = "pagseguro"
}

# POST /webhook/pagseguro (sem autenticação)
resource "aws_api_gateway_method" "webhook_pagseguro_post" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.webhook_pagseguro.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "webhook_pagseguro_post" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.webhook_pagseguro.id
  http_method = aws_api_gateway_method.webhook_pagseguro_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_pedidopgto_url}/api/webhook/pagseguro"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recursos e métodos para /pagamento
resource "aws_api_gateway_resource" "pagamento" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_rest_api.order_system_api.root_resource_id
  path_part   = "pagamento"
}

# Recurso para /pagamento/{pedidoId}
resource "aws_api_gateway_resource" "pagamento_id" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_resource.pagamento.id
  path_part   = "{pedidoId}"
}

# POST /pagamento/{pedidoId}
resource "aws_api_gateway_method" "pagamento_post" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.pagamento_id.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.pedidoId" = true
  }
}

resource "aws_api_gateway_integration" "pagamento_post" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.pagamento_id.id
  http_method = aws_api_gateway_method.pagamento_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_pedidopgto_url}/api/pagamento/{pedidoId}"

  request_parameters = {
    "integration.request.path.pedidoId" = "method.request.path.pedidoId"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recursos e métodos para /cliente
resource "aws_api_gateway_resource" "cliente" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_rest_api.order_system_api.root_resource_id
  path_part   = "cliente"
}

# GET /cliente (listar todos)
resource "aws_api_gateway_method" "cliente_get_all" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.cliente.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "cliente_get_all" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.cliente.id
  http_method = aws_api_gateway_method.cliente_get_all.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_cliente_url}/api/cliente"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# POST /cliente (criar)
resource "aws_api_gateway_method" "cliente_post" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.cliente.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "cliente_post" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.cliente.id
  http_method = aws_api_gateway_method.cliente_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_cliente_url}/api/cliente"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recurso para /cliente/{clienteId}
resource "aws_api_gateway_resource" "cliente_id" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_resource.cliente.id
  path_part   = "{clienteId}"
}

# GET /cliente/{clienteId}
resource "aws_api_gateway_method" "cliente_get_id" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.cliente_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.clienteId" = true
  }
}

resource "aws_api_gateway_integration" "cliente_get_id" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.cliente_id.id
  http_method = aws_api_gateway_method.cliente_get_id.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_cliente_url}/api/cliente/{clienteId}"

  request_parameters = {
    "integration.request.path.clienteId" = "method.request.path.clienteId"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recursos e métodos para /pedido
resource "aws_api_gateway_resource" "pedido" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_rest_api.order_system_api.root_resource_id
  path_part   = "pedido"
}

# GET /pedido (listar todos)
resource "aws_api_gateway_method" "pedido_get_all" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.pedido.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "pedido_get_all" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.pedido.id
  http_method = aws_api_gateway_method.pedido_get_all.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_pedidopgto_url}/api/pedido"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# GET /pedido/ativos
resource "aws_api_gateway_resource" "pedido_ativos" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_resource.pedido.id
  path_part   = "ativos"
}

resource "aws_api_gateway_method" "pedido_get_ativos" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.pedido_ativos.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "pedido_get_ativos" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.pedido_ativos.id
  http_method = aws_api_gateway_method.pedido_get_ativos.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_pedidopgto_url}/api/pedido/ativos"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# POST /pedido (criar)
resource "aws_api_gateway_method" "pedido_post" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.pedido.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "pedido_post" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.pedido.id
  http_method = aws_api_gateway_method.pedido_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_pedidopgto_url}/api/pedido"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recurso para /pedido/{pedidoId}
resource "aws_api_gateway_resource" "pedido_id" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_resource.pedido.id
  path_part   = "{pedidoId}"
}

# GET /pedido/{pedidoId}
resource "aws_api_gateway_method" "pedido_get_id" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.pedido_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.pedidoId" = true
  }
}

resource "aws_api_gateway_integration" "pedido_get_id" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.pedido_id.id
  http_method = aws_api_gateway_method.pedido_get_id.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_pedidopgto_url}/api/pedido/{pedidoId}"

  request_parameters = {
    "integration.request.path.pedidoId" = "method.request.path.pedidoId"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Continuação do script...

# PUT /pedido/{pedidoId}/status
resource "aws_api_gateway_resource" "pedido_status" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_resource.pedido_id.id
  path_part   = "status"
}

resource "aws_api_gateway_method" "pedido_put_status" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.pedido_status.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.pedidoId" = true
  }
}

resource "aws_api_gateway_integration" "pedido_put_status" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.pedido_status.id
  http_method = aws_api_gateway_method.pedido_put_status.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "PUT"
  uri                    = "http://${var.lb_pedidopgto_url}/api/pedido/{pedidoId}/status"

  request_parameters = {
    "integration.request.path.pedidoId" = "method.request.path.pedidoId"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recursos e métodos para /produto
resource "aws_api_gateway_resource" "produto" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_rest_api.order_system_api.root_resource_id
  path_part   = "produto"
}

# GET /produto (listar todos)
resource "aws_api_gateway_method" "produto_get_all" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.produto.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "produto_get_all" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.produto.id
  http_method = aws_api_gateway_method.produto_get_all.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_produto_url}/api/produto"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# POST /produto (criar)
resource "aws_api_gateway_method" "produto_post" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.produto.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "produto_post" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.produto.id
  http_method = aws_api_gateway_method.produto_post.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "POST"
  uri                    = "http://${var.lb_produto_url}/api/produto"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recurso para /produto/{produtoId}
resource "aws_api_gateway_resource" "produto_id" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_resource.produto.id
  path_part   = "{produtoId}"
}

# GET /produto/{produtoId}
resource "aws_api_gateway_method" "produto_get_id" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.produto_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.produtoId" = true
  }
}

resource "aws_api_gateway_integration" "produto_get_id" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.produto_id.id
  http_method = aws_api_gateway_method.produto_get_id.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_produto_url}/api/produto/{produtoId}"

  request_parameters = {
    "integration.request.path.produtoId" = "method.request.path.produtoId"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# PUT /produto/{produtoId}
resource "aws_api_gateway_method" "produto_put" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.produto_id.id
  http_method   = "PUT"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.produtoId" = true
  }
}

resource "aws_api_gateway_integration" "produto_put" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.produto_id.id
  http_method = aws_api_gateway_method.produto_put.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "PUT"
  uri                    = "http://${var.lb_produto_url}/api/produto/{produtoId}"

  request_parameters = {
    "integration.request.path.produtoId" = "method.request.path.produtoId"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# DELETE /produto/{produtoId}
resource "aws_api_gateway_method" "produto_delete" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.produto_id.id
  http_method   = "DELETE"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.produtoId" = true
  }
}

resource "aws_api_gateway_integration" "produto_delete" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.produto_id.id
  http_method = aws_api_gateway_method.produto_delete.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "DELETE"
  uri                    = "http://${var.lb_produto_url}/api/produto/{produtoId}"

  request_parameters = {
    "integration.request.path.produtoId" = "method.request.path.produtoId"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Recurso para /produto/categoria/{categoria}
resource "aws_api_gateway_resource" "produto_categoria" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_resource.produto.id
  path_part   = "categoria"
}

resource "aws_api_gateway_resource" "produto_categoria_id" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_resource.produto_categoria.id
  path_part   = "{categoria}"
}

resource "aws_api_gateway_method" "produto_get_categoria" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.produto_categoria_id.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.path.categoria" = true
  }
}

resource "aws_api_gateway_integration" "produto_get_categoria" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.produto_categoria_id.id
  http_method = aws_api_gateway_method.produto_get_categoria.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_produto_url}/api/produto/categoria/{categoria}"

  request_parameters = {
    "integration.request.path.categoria" = "method.request.path.categoria"
  }
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Rota de teste sem autenticação
resource "aws_api_gateway_resource" "test" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  parent_id   = aws_api_gateway_rest_api.order_system_api.root_resource_id
  path_part   = "test"
}

resource "aws_api_gateway_method" "test" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.test.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "test" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.test.id
  http_method = aws_api_gateway_method.test.http_method
  type        = "HTTP_PROXY"
  
  integration_http_method = "GET"
  uri                    = "http://${var.lb_cliente_url}/api/cliente"
  
  timeout_milliseconds    = 29000
  connection_type        = "INTERNET"
}

# Configurações de CORS
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  resource_id   = aws_api_gateway_resource.cliente.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.cliente.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.cliente.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  resource_id = aws_api_gateway_resource.cliente.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

# Continuação do deploy da API...
# Deploy da API
resource "aws_api_gateway_deployment" "order_system" {
  rest_api_id = aws_api_gateway_rest_api.order_system_api.id
  
  depends_on = [
    aws_api_gateway_integration.webhook_pagseguro_post,
    aws_api_gateway_integration.pagamento_post,
    aws_api_gateway_integration.cliente_get_all,
    aws_api_gateway_integration.cliente_post,
    aws_api_gateway_integration.cliente_get_id,
    aws_api_gateway_integration.pedido_get_all,
    aws_api_gateway_integration.pedido_post,
    aws_api_gateway_integration.pedido_get_ativos,
    aws_api_gateway_integration.pedido_get_id,
    aws_api_gateway_integration.pedido_put_status,
    aws_api_gateway_integration.produto_get_all,
    aws_api_gateway_integration.produto_post,
    aws_api_gateway_integration.produto_get_id,
    aws_api_gateway_integration.produto_put,
    aws_api_gateway_integration.produto_delete,
    aws_api_gateway_integration.produto_get_categoria
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Estágio da API
resource "aws_api_gateway_stage" "order_system" {
  deployment_id = aws_api_gateway_deployment.order_system.id
  rest_api_id   = aws_api_gateway_rest_api.order_system_api.id
  stage_name    = "v1"
}

variable "lb_pedidopgto_url" {
  description = "URL do LoadBalancer do serviço de Pedido e Pagamentos"
  type        = string
}

variable "lb_produto_url" {
  description = "URL do LoadBalancer do serviço de Produto"
  type        = string
}

variable "lb_cliente_url" {
  description = "URL do LoadBalancer do serviço de Cliente"
  type        = string
}

# Outputs
output "api_gateway_url" {
  value = "${aws_api_gateway_stage.order_system.invoke_url}"
}

output "api_gateway_arn" {
  value = aws_api_gateway_rest_api.order_system_api.execution_arn
}
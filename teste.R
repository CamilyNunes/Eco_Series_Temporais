# Instale o pacote urca caso não tenha
if (!require(urca)) install.packages("urca")
library(urca)

# Carregar o dataset
# Substitua o caminho abaixo pelo local do seu arquivo
df <- read.csv("caminho/do/seu/arquivo.csv")

# Visualizando as primeiras linhas para verificar o carregamento correto
head(df)

colnames(df)

# Transformar a coluna Data em formato de data (caso não esteja)
df$Data <- as.Date(df$Data, format = "%Y-%m-%d")

# Lista de variáveis a serem testadas
variaveis <- c("selic", "dslp", "Desem", "PIBacun12m")

# Função para realizar o teste ADF
teste_adf <- function(variavel) {
  cat("\n\nTeste ADF para:", variavel, "\n")
  serie <- na.omit(df[[variavel]])
  
  # Teste ADF com intercepto e tendência
  adf <- ur.df(serie, type = "trend", lags = 12, selectlags = "AIC")
  
  # Exibir resumo do teste
  print(summary(adf))
}

# Aplicando o teste ADF para cada variável
lapply(variaveis, teste_adf)

summary(df)

# Pacotes instalados: roda uma vez somente e deixa como comentário
install.packages("sandwich")
install.packages("readxl")
install.packages("aTSA")
install.packages("lmtest")
install.packages("strucchange")

# Carregar os pacotes toda vez que for rodar
library(readxl) # Para abrir a planilha em excel
library(urca) # para os testes de raíz unitária
library(aTSA) # é um pacote parecido com o urca. Vamos usar pois o urca não tem o teste de Engle-Granger
library (lmtest) # Teste para a forma funcional
library(tseries) # O teste Jarque-Bera (de normalidade) está nesse pacote
library(strucchange) # Pacote para analisar quebras estruturais

setwd("C:/Juliano/Universidade/Disciplinas/Series Temporais")

Dados <- read_excel("C:/Juliano/Universidade/Disciplinas/Series Temporais/PIB_consumo.xlsx")


# Criando as séries temporais
PIB = ts(Dados$PIB[1:114], start= c(1996, 1), freq=4)
# Veja que são dados trimestrais freq = 4
Consumo = ts(Dados$Consumo[1:114], start= c(1996, 1), freq=4)
# Veja que são dados trimestrais freq = 4
#Gráficos
ts.plot(PIB, Consumo)
#Testes de Raíz Unitária
summary(ur.df(PIB, type="trend", lags=8, selectlags = "AIC"))
summary(ur.df(Consumo, type="trend", lags=8, selectlags = "AIC"))
# Ambas séries são não estacionárias: não rejeitamos a raíz unitária

coint.test(PIB, Consumo, d = 0, nlag = NULL, output = TRUE)
# O teste é sobre a raíz unitária dos resíduos do regressão PIB x Consumo
# Rejeitamos a raíz unitária a 10% de significância: 4.0000 -2.6838  0.0832 
# Mas não rejeitamos a 5% e a 1%. Isto é, não foi uma rejeitção muito forte! Tudo bem.

# A conintegração vai garantir que não cairemos numa regressão espúria.
# Vamos explicar o Consumo a partir do PIB
reg <- lm (Consumo ~ PIB)
summary (reg)
#Resultado: para cada 1 real de variação no PIB, temos 1,22958 real de variação no consumo
#Adjusted R-squared:  0.9788
# Vamos ver os residuos
ts.plot(reg$residuals)
# Realmente não parecem estacionários
# Isso não é bom.
# Provavelmente tem um problema nessa regressão.
# Mas vamos manter o que encontramos.
plot(Consumo, PIB)
abline (reg, col = 'red', lwd = 3)
# Por serem duas séries temporais, o gráfico ficou feio
# Pegando os dados diretos da planilha fica melhor
plot(Dados$Consumo, Dados$PIB)
abline (reg, col = 'red', lwd = 3)
# Perceba que a linha não passou muito bem sobre os dados
# Teste para forma funcional. H0: o modelo foi especificado corretamente
resettest (reg)
# Rejeita h0: p-value < 2.2e-16
# Teste Breusch and Pagan(H0: os erros são homoscedásticos)
bptest (reg)
# p-value = 0.0004901 então rejeitamos a presença de homoscedasticidade.Há heteroscedasticidade
# Testaremos a normalidade dos resíduos
jarque.bera.test(reg$residuals)
# não se rejeita a hipótese de normalidade: p-value = 0.1865
# Teste de Durbin-Watson para Autocorrelação (H0: não há autocorrelação)
dwtest(reg)
# O resultado DW = 0.1547 (longe de 2,00) com p-value < 2.2e-16 rejeita H0: não há autocorrelação (não é bom também)
#Teste de Breusch-Godfrey (BG) H0:não há autocorrelação
bgtest(reg)
# O resultado p-value < 2.2e-16 rejeita H0:não há autocorrelação

# Podemos verificar também se há quebra estrutural na regressão. H0: não há quebra
sctest(reg)
#Rejeita-se H0 (p-value = 7.355e-08)
# Abaixo podemos ver isso graficamente
quebra <- efp(Consumo ~ PIB)
plot(quebra)
# Podemos tentar achar os pontos de quebra
pontos <- breakpoints(Consumo ~ PIB)
pontos
coef(pontos)

# Observações: desses testes pode sair uma monografia
# Estimação da função de consumo keynesiana. Seu valor é constante? 
# Lembre-se que os dados não estão deflacionados
# Se transformarmos as séries em log, provavelmente os resultados serão melhores
# Outra sugestão é fazer os cálculos com as variáveis per capita


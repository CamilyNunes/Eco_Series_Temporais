# Pacotes instalados: roda uma vez somente e deixa como comentário

#install.packages("UsingR")
#install.packages("fpp")
#install.packages("mFilter")
#install.packages("readxl")
#install.packages("seasonal")
#install.packages("urca")
#install.packages("FinTS")
#install.packages("tsoutliers") 
#install.packages("forecast")


# Carregar os pacotes toda vez que for rodar
library(UsingR) # Para construir gráficos básicos
library(fpp)    # Para acessar a série elecequip
library(mFilter) # filtro Hodrick-Prescott
library(readxl) # Para abrir a planilha em excel
library(seasonal) # Para rodar o X-13 ARIMA
library(urca)  # Para fazer os testes de raíz unitária
library(FinTS) # Para testar a estabilidade da variância do ARIMA
library(tsoutliers) # # Substitui o pacote "normtest" para o teste de normalidade do ARIMA
library(forecast) # Para fazer as previsões do ARIMA


# Galton é uma base de dados com 928 medidas de altura de pais e seus respectivos filhos
galton
head(galton)

#Convertendo de Polegadas para centímetros (1" = 2,54cm)
# parent = média entre pai e mãe
# child = filho

galton <-2.54*galton
head(galton)

################################### Hitograma para a altura dos filhos #################

hist(galton$child, main = "", xlab = "Altura (cm)", ylab = "Frequencia", ylim=c(0,200))
#Se quiser acrescentar alguma cor no gráfico
hist(galton$child, main = "", xlab = "Altura (cm)", ylab = "Frequencia", ylim=c(0,200),col = "lightgray", border = "steelblue")

################################# Boxplot para a altura dos pais ##############################

# O gráfico Boxplot é bom para encontrar outliers (dados discrepantes)
boxplot(galton$parent, main ="", ylab = "Altura (cm)", col = "seagreen3")

################################# Gráficos de dispersão ##########################
# kid.weights é uma base de dados com uma amostra de 250 crianças com idade, peso, altura e sexo
# Age in months: 
# weight in pounds: 1 libra = 0,45Kg
# height in inches: 1 polegada = 2,54cm
# Male of Female

head(kid.weights)
kid.weights$weight <- kid.weights$weight*0.45
kid.weights$height <- kid.weights$height*2.54/100

plot(x = kid.weights$weight, y = kid.weights$height, main = "", xlab = "Peso", ylab = "Altura")
# Vamos fazer uma regressão MQO
regressao = lm(kid.weights$height ~ kid.weights$weight, data = kid.weights)
summary(regressao)
regressao
abline(a=0.58,b=0.02)

################################### Gráficos de Pizza ####################

# Com os dados kid.weights, mostraremos um gráfico de pizza com a proporção dos meninos e meninas da amostra
prop <- table(kid.weights[,4])
prop
pie(prop, main = "", labels = c("51,6%","48,4%"), col = c("palevioletred2", "dodgerblue3"))
#adicionar legenda
legend(x = "topright", bty = "n", cex = 0.8, legend = c("Feminino", "Masculino"), fill = c("palevioletred2", "dodgerblue3"))

################################### Gráficos de Barra

# Com os dados "grades" com 122 alunos com notas entre A e F em dois períodos (Vamos considerar do período 1)
grades
tabela1 <- table(grades[,1])
barplot(tabela1, main = "", colo = topo.colors(9))

################################## Gráfico de uma série temporal #################

# Utilizaremos a série elecequip do pacote fpp instalado: é um índice de novos pedidos de fabricação de eletônicos em 16 países da Europa
data(elecequip)
plot(elecequip, xlab = "Tempo", ylab = "ìndice de novas Ordens")

#Decompondo a série em Tendência, Sazonalidade e (Ciclo + Aleatório)
decomp<-decompose(elecequip, type='additive')
plot(decomp)

# O Filtro Hodrick-Prescott é um meio muito utilizado para separar a tendência das séries
# Utiliza-se o pacote mFilter

filtro_hp <- hpfilter(elecequip, type= "lambda")
ts.plot(elecequip, filtro_hp$trend)

#Baixando uma planilha do excel

setwd("C:/Juliano/Universidade/Disciplinas/Series Temporais")

Dados <- read_excel("C:/Juliano/Universidade/Disciplinas/Series Temporais/PIB_Mensal.xlsx")


# Criando as séries temporais
PIB = ts(Dados$PIB[1:354], start= c(1995, 2), freq=12)


ts.plot(PIB)


summary(PIB) # Algumas estatísticas básicas
sd(PIB) # Desvio-padrão

# Vamos verificar se existe sazonalidade na série do PIB

decomp_PIB<-decompose(PIB, type='additive')
plot(decomp_PIB)

# Parece que realmente existe sazonalidade.
# Para corrigir, o melhor método é o X13-ARIMA.
# Desenvolvido pelo  U.S Census Bureau com o apoio do Bank of Spain
# Está no pacote "seasonal"
# O capítulo 5 do livro "Análise de Séries Temporais em R" aprofunda mais o tema. Aqui é somente uma introdução.

AjusteX13_PIB <- seas(PIB, transform.function = "none")
plot(AjusteX13_PIB)

PIB_AS <- final(AjusteX13_PIB)
ts.plot(PIB_AS, PIB)

# Perceba que a variância da série aumenta junto com o aumento dos dados
# Na literatura é muito comum o uso de séries em logaritmo
# Essa transformação estabiliza a variância

ln_PIB_AS <- log(PIB_AS)
ts.plot(ln_PIB_AS)

############################################# Testes de Estacionariedade ######################3

# Testes Dickey- Fuller Aumentado 
summary(ur.df(ln_PIB_AS, type="none", lags=8, selectlags = "AIC"))
# "none": sem tendência e sem deslocamento
#Resultado: coeficiente delta da nossa fórmula (z.lag.1) é positivo = 0.0007737
# Se delta é positivo (delta = ro - 1), ro > 1 implica que a série é explosiva. (p.748 do Gujarati)
# Esse teste deve ser descartado
# Observemos Value of test-statistic is: 6.878
# O p-valor é posivivo por causa do delta positivo. Deve ser descartado.
summary(ur.df(ln_PIB_AS, type="drift", lags=8, selectlags = "AIC"))
# "drift": sem tendência e com deslocamento
# Resultado: coeficiente delta da nossa fórmula (z.lag.1) é negativo = -0.002205. Ok!
# Observemos Value of test-statistic is tau2 = -1.9508
# Critical values for test statistics: tau2 (1%)=-3.44 (5%)=-2.87 (10%)=-2.57
# Como não rejeita os valores críticos, não rejeitamos a raiz unitária nem a 10%. Portanto, série não estacionária.
summary(ur.df(ln_PIB_AS, type="trend", lags=8, selectlags = "AIC"))
# "trend": com tendência e com deslocamento
# Resultado: coeficiente delta da nossa fórmula (z.lag.1) é negativo = -1.238e-02 ~ -0.001238. Ok!
# Observemos Value of test-statistic is tau3 = -1.3208
# Critical values for test statistics: tau2 (1%)=-3.98 (5%)=-3.42 (10%)=-3.13
# Como não rejeita os valores críticos, não rejeitamos a raiz unitária nem a 10%. Portanto, série não estacionária.
# É comum nos trabalhos empíricos realizar somente um teste, desde que tau < 0.

# Testes Phillips-Perron em nível
summary(ur.pp(ln_PIB_AS, type = "Z-tau", model = "trend", lags = "long"))
# Z-tau  is: -1.5038 e também rejeita pelos Critical values for Z statistics

# Testes KPSS em nível
summary(ur.kpss(ln_PIB_AS, type = "tau", lags = "long"))
# O teste KPSS é um teste de estacionariedade e não raiz unitária. Portanto H0 é estacionariedade.
# Diferente do DFA onde H0 é raiz unitária.
# A estatística do teste é: 0,4556. É maior do que o valor crítico para qualquer nível de significância
# e portanto rejeita HO a 10%, 5%, 2,5% e 1% de significância.

# Testes DF-GLS em nível
summary(ur.ers(ln_PIB_AS, type = "DF-GLS", model = "trend", lag.max = 4))
# Value of test-statistic is: -0.563. Portanto, não rejeita a raiz unitária

# Testes Zivot-Andrews em nível
summary(ur.za(ln_PIB_AS, model = "trend", lag = 4))
# Teststatistic: -2.675. Portanto, não rejeita a raiz unitária.

##### CONCLUSÃO: os testes de raiz unitária foram unânimes em não rejeitar a raiz unitária. Isso implica em não estacionariedade
##### O teste KPSS rejeitou a estacionariedade.
#### Portanto ln_PIB_AS é não estacionária.

# Vamos dar uma olhada nas funções de autocorrelação e autocorrelação parcial
acf(ln_PIB_AS, 36, main = "FAC do PIB")
# coeficiente de autocorrelação altos e descrescem lentamente
pacf(ln_PIB_AS, 36, main = "FACP do PIB")
# A primeira defasagem da autocorrelação parcial é igual a 1.
# Portanto, pelos FAC e FACP a série do PIB também é não estacionária.
# Veja no Gujarati, p.744, Figura 21.6, como seria FAC e FACP de uma série estacionária!

############# Diferenciar e extrair a tendência para tornar estacionária

# A série ln_PIB_SA parece então ter raiz unitária. Seu gráfico ajuda com essa interpretação.
# A tendência temporal também é uma possibilidade.
# Vamos verificar se é de tendência estacionária (TE) ou diferença estacionária (DE)
ts.plot(ln_PIB_AS)

##################### verificando se é de tendência estacionária (TE)
Tempo=double(354)
for (j in 1:(354)){
  Tempo[j]=j
}

regPIB_Tempo <- lm(ln_PIB_AS ~ Tempo)
summary(regPIB_Tempo)
#Coefficients:
#             Estimate Std. Error t value Pr(>|t|)    
#(Intercept) 1.107e+01  1.027e-02  1078.1   <2e-16 ***
#Tempo       8.001e-03  5.012e-05   159.6   <2e-16 ***
ln_PIB_AS_ST <- regPIB_Tempo$residuals # ST significa sem tendência
ts.plot(ln_PIB_AS_ST)
# Parece que não é uma série te tendência estacionária.
summary(ur.df(ln_PIB_AS_ST, type="trend", lags=8, selectlags = "AIC"))
# Value of test-statistic is: -1.3208. Não é mesmo!

##################### Verificando se é de ou diferença estacionária (DE)

# Estraindo a primeira diferença, temos:
d_ln_PIB_AS <- diff(ln_PIB_AS) # O comando diff() é para extrair a primeira diferença (Yt - Yt-1)
ts.plot(d_ln_PIB_AS)
# Parece estacionária hein!!!
summary(ur.df(d_ln_PIB_AS, type="trend", lags=8, selectlags = "AIC"))
#Value of test-statistic is: -7.72. Maior que o valor crítico a 1% de significânia. Não possui raiz unitária!
summary(ur.df(d_ln_PIB_AS, type="none", lags=8, selectlags = "AIC"))
# Value of test-statistic is: -2.5253 . Rejeita a raiz unitária a 5%
summary(ur.df(d_ln_PIB_AS, type="drift", lags=8, selectlags = "AIC"))
# Value of test-statistic is: -7.5172.  Rejeita a raiz unitária a 1%

summary(ur.kpss(d_ln_PIB_AS, type = "tau", lags = "long"))
# Value of test-statistic is: 0.0782. H0 é a estacionariedade. Não rejeita a estacionariedade!
# CONCLUSÃO: ln_PIB_SA é uma série de diferença estacionária (DE)


######################### Previsão com modelo ARIMA

# Vamos fazer uma previsão com o PIB
# Para simplificar, não vamos deflacionar. Mas num trabalho empírico é necessário deflacionar.
# Vamos utilizar o PIB sem deflacionar com o ajuste sazonal.

ts.plot(PIB_AS)

############## Passo 1 do Gujarati: Identificação para descobrir (p,d,q)
# Funções de AC e ACP
acf(PIB_AS, 36, main = "FAC do PIB")
# coeficiente de autocorrelação altos e descrescem lentamente
pacf(PIB_AS, 36, main = "FACP do PIB")
# A série parece não estacionária. Faremos o teste Dickey-Fuller Aumentado
summary(ur.df(PIB_AS, type="trend", lags=8, selectlags = "AIC"))
# Value of test-statistic is: 0.8017. Não estacionária!
# Vamos diferenciar
d_PIB_AS <- diff(PIB_AS)
# Gráfico
ts.plot(d_PIB_AS)
# Correlograma
acf(d_PIB_AS, 36, main = "FAC do PIB")
pacf(d_PIB_AS, 36, main = "FACP do PIB")
#Teste Dickey_fuller Aumentado
summary(ur.df(d_PIB_AS, type="trend", lags=8, selectlags = "AIC"))
# Value of test-statistic is: -6.1852. Rejeita-se a raiz unitária na primeira diferença!
# Pelos padrões da FA e FAP segundo o Gujarati, estimaremos um ARIMA (1,1,13)
# O q = 13 é muito elevado. Mas vamos rodar.

############## Passo 2 do Gujarati: Estimação do ARIMA (p,d,q)
Prev_PIB <- arima(PIB_AS,order=c(1,1,13))
summary(Prev_PIB)

############## Passo 3 do Gujarati: Diagnóstico do ARIMA (p,d,q)
tsdiag(Prev_PIB)
# Há AC nos resíduos, o que não é bom
# Testaremos H0: não há existência de autocorrelação
Box.test(Prev_PIB$residuals,lag=24, type = "Ljung-Box")
Box.test(Prev_PIB$residuals,lag=24, type = "Box-Pierce")
# Não rejeitamos H0: não há existência de autocorrelação serial até o 24 lag
# Testaremos H0: não há heteroscedasticidade
ArchTest(Prev_PIB$residuals,lag=24)
# p-value = 3.093e-06 rejeitamos a não hetersocedasticidade. Mais um problema!
# Testaremos a normalidade dos resíduos
jarque.bera.test(residuals(Prev_PIB))
# p-value < 2.2e-16 rejeitamos a normalidade dos resíduos (outro problema)
### CONCLUSÃO: O modelo ARIMA(1,1,13) não é bom
# Vamos deixar esse desafio para um TCC! Alguém sem tema? Vamos seguir com as previsões com ele mesmo assim

############## Passo 4 do Gujarati: Previsão do ARIMA (p,d,q)
plot(forecast(object = Prev_PIB, h = 12, level = 0.95))
# O que você achou? Ficou aparentemente bom?
# Vefificar o erro de previsão MAPE (Mean Absolute Percentage Error)
accuracy(Prev_PIB)
# O erro de previsão está em 1.346492%
# Parece bom apesar dos problemas de diagnóstico. Uma possível solução é trabalhar com a ln_PIB.
# Devemos deflacionar a série.
# Podemos usar os critérios de seleção de defasagem AIC, BIC... para ajudar a selecionar as defasagens
# Uma outra opção é estimar um modelo SARIMA (ARIMA com controle sazonal)
# Nesse caso, usaremos a série do PIB sem ajuste sazonal seguindo a capítulo 4 de "Introdução de Séries Temposrais em R"

##################################### SARIMA, Cap 4 do livro de Séries

data("AirPassengers")
# The “AirPassengers” dataset in R contains the monthly totals of international airline passengers from 1949 to 1960.
ts.plot(AirPassengers, ylab = "Vendas de Passagens Aéreas", xlab = "Anos")
monthplot(AirPassengers, ylab = "Vendas de Passagens Aéreas", xlab = "Meses")
# Veja que a média dos meses junho, julho e agosto são maiores

#################################### Parte 1 - identificação
plot(decompose(AirPassengers))
# Veja o componente sazonal
acf(AirPassengers, 36, main = "FAC das Vendas de Passagens Aéreas")
# Vamos testar a raiz unitária atravéz do teste Dickey-Fuller Aumentado
summary(ur.df(AirPassengers, type="drift", lags=24, selectlags = "AIC"))
# Veja que z.lag.1 = 0.02250 > 0 e o p-valor = 1.8582 > 0.
# Portanto o teste com drift não é adequado. Vamos testar com "trend"
summary(ur.df(AirPassengers, type="trend", lags=24, selectlags = "AIC"))
# Value of test-statistic is: -1.3564: Não rejeita H0: possui raiz unitária
# Vamos ter de obter a primeira diferença
d_AirPassengers <- diff(AirPassengers)
ts.plot(d_AirPassengers)
# A Variância não é constante. Ela aumenta com o tempo. Corrigimos isso com a transformação logarítmica
ln_AirPassengers <- log(AirPassengers)
d_ln_AirPassengers <- diff(ln_AirPassengers)
ts.plot(d_ln_AirPassengers)
# A tranformação logarítmica estabilizou a variância da série
acf(d_ln_AirPassengers, 36, main = "FAC das Vendas de Passagens Aéreas")
# Não decresce lentamente: um sinal para a ausência de raiz unitária. Faremos o teste Dickey-Fuller Aumentado
summary(ur.df(d_ln_AirPassengers, type="none", lags=24, selectlags = "AIC")) 
#Usamos "none" (sem deslocamento e tendência) pois a série parece não ter tendência e deslocamento.
# Porém, se realizarmos novamente com drift ou trend, os testes ainda rejeitam a raiz unitária. Veja isso!
# Considerando a série estacionária, vamos estimar o SARIMA

#################################### Parte 2 - Estimação
SARIMA <-  Arima(ln_AirPassengers, order = c(0,1,1), seasonal = c(0,1,1))
summary(SARIMA)

###################################### Parte 3 - Diagnóstico
tsdiag(SARIMA)
# Há AC nos resíduos, o que não é bom
# Testaremos H0: não há existência de autocorrelação
Box.test(SARIMA$residuals,lag=24, type = "Ljung-Box")
Box.test(SARIMA$residuals,lag=24, type = "Box-Pierce")
# Não rejeitamos H0: não há existência de autocorrelação serial. Bom!
# Testaremos H0: homocedasticidade
ArchTest(SARIMA$residuals,lag=12)
# p-value = 0.2493: não rejeitamos a homocedasticidade. Isso é bom!
# Testaremos a normalidade dos resíduos
jarque.bera.test(residuals(SARIMA))
# Não rejeitamos a normalidade a 5% de significância. Bom também.

###################################### Parte 3 - Estimação

plot(forecast(object = SARIMA, h=12, level = 0.95))
# Interessante!
accuracy(SARIMA)
# O erro de previsão é apenas de 0.47%





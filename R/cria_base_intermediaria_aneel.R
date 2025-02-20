
#' Cria a base intemediária para a aneel criando um dataframe
#' @import dplyr
#' @import tidyr
#' @import lubridate
#' @import stringr
#' @import readr
#' @return
#' @export
#'
#' @examples
cria_base_intermediaria_aneel <- function(
  origem_processos = here::here("data/SGPED_BI/PD Busca Textual.csv"),
  origem_equipes = here::here("data/SGPED_BI/5.PD RF EQUIPE.csv")
){


  options(scipen=999)
  ##get the data ##

  #importando o dataset
  anel_pd <- readr::read_delim(origem_processos,
                        ";", escape_double = FALSE, locale = readr::locale(encoding = "latin1"),
                        trim_ws = TRUE) %>%
    janitor::clean_names()

  anel_pd <- anel_pd%>%
    dplyr::mutate(data_de_carregamento   = lubridate::as_date(lubridate::dmy_hms(data_de_carregamento)),
           data_de_conclusao             = lubridate::dmy(data_de_conclusao),
           duracao_prevista              = lubridate::date(data_de_carregamento+lubridate::dmonths(duracao_prevista_meses)),
           data_de_conclusao             = dplyr::case_when(is.na(data_de_conclusao) ~ duracao_prevista,
                                              TRUE~data_de_conclusao ),
           custo_total_previsto          = as.numeric(stringr::str_replace_all(
                                           stringr::str_replace_all(custo_total_previsto, "[.$]", ""), "[,]", "." )),
           custo_total_realizado         = as.numeric(stringr::str_replace_all(
                                           stringr::str_replace_all(custo_total_realizado, "[.$]", ""), "[,]", "." )),
           custo_total_realizado         = dplyr::case_when(is.na(custo_total_realizado) ~ custo_total_previsto,
                                           TRUE~custo_total_realizado),
           duracao_dias                  = lubridate::time_length(data_de_conclusao - data_de_carregamento, "days"),
           #duracao_dias           = interval(data_de_carregamento, data_de_conclusao)/ddays(),
           duracao_anos                  = as.integer(lubridate::interval(data_de_carregamento, data_de_conclusao)/lubridate::dyears()),
           motor                         = stringi::stri_trans_general(paste(titulo,segmento,tema),
                                                                "Latin-ASCII"),
           motor                         = tolower(motor)) %>%
    dplyr::filter(duracao_prevista >= "2013-01-01") %>%
    tidyr::drop_na(custo_total_previsto)

   #Old function
#  anel_pd <- func_a(anel_pd,
#                                data_assinatura = anel_pd$data_de_carregamento,
#                                data_limite = anel_pd$data_de_conclusao,
#                                duracao_dias = anel_pd$duracao_dias,
#                                valor_contratado = anel_pd$custo_total_previsto)

   anel_pd <- func_a(anel_pd, cod_proj, data_de_carregamento,
                     data_de_conclusao,custo_total_previsto)

   anel_pd <- dtc_categorias(anel_pd,cod_proj, motor)

   anel_pd <- anel_pd %>% dplyr::mutate(categorias = dplyr::recode(categorias,
                                                        "character(0" = "nenhuma categoria encontrada"))

  aneel_time <- readr::read_csv2(origem_equipes)%>%
    dplyr::filter(`Tipo de Entidade` == "Proponente")  %>%
    dplyr::select(CodProj,`Entidade Vinculada`,`Unidade Federativa`) %>%
    dplyr::distinct() %>%
    janitor::clean_names()

  anel_pd <- dplyr::left_join(anel_pd, aneel_time, by = "cod_proj")

  anel_pd<- anel_pd %>% dplyr::mutate(regiao_ag_executor = dplyr::recode(unidade_federativa,
                                                           "AC" = "N",
                                                           "AL" = "NE",
                                                           "AM" = "N",
                                                           "BA" = "NE",
                                                           "CE" = "NE",
                                                           "DF" = "CO",
                                                           "ES" = "SE",
                                                           "GO" = "CO",
                                                           "MA" = "NE",
                                                           "MG" = "SE",
                                                           "MS" = "CO",
                                                           "MT" = "CO",
                                                           "PA" = "N",
                                                           "PB" = "NE",
                                                           "PE" = "NE",
                                                           "PI" = "NE",
                                                           "PR" = "S",
                                                           "RJ" = "SE",
                                                           "RN" = "NE",
                                                           "RO" = "N",
                                                           "RS" = "S",
                                                           "SC" = "S",
                                                           "SE" = "NE",
                                                           "SP" = "SE",
                                                           "TO" = "N"
  ))
  anel_pd <- anel_pd %>%
    dplyr::mutate(
           id                          = paste("ANEEL", cod_proj, sep = "-"),
           fonte_de_dados                 = "ANEEL",
           data_assinatura             = data_de_carregamento,
           data_limite                 = data_de_conclusao,
           duracao_dias                = duracao_dias,
           duracao_meses               = duracao_prevista,
           valor_contratado            = custo_total_previsto,
           valor_executado_2013_2020   = gasto_2013_2020,
           nome_agente_financiador     = proponente,
           natureza_agente_financiador = "Empresa Privada", # confirmar
           natureza_financiamento    = "Publicamente Orientado",
           modalidade_financiamento    = "Não se Aplica",
           nome_agente_executor        = entidade_vinculada,
           natureza_agente_executor    = "Empresa Privada", # confirmar
           'p&d_ou_demonstracao'       = NA,
           titulo_projeto              = titulo,
           status_projeto              = situacao,
           uf_ag_executor              = unidade_federativa,
           valor_executado_2013        = gasto_2013,
           valor_executado_2014        = gasto_2014,
           valor_executado_2015        = gasto_2015,
           valor_executado_2016        = gasto_2016,
           valor_executado_2017        = gasto_2017,
           valor_executado_2018        = gasto_2018,
           valor_executado_2019        = gasto_2019,
           valor_executado_2020        = gasto_2020,
           motor
    )



  anel_pd <- anel_pd %>%
    dplyr::select(
      id,
      fonte_de_dados,
      data_assinatura,
      data_limite,
      duracao_dias,
      titulo_projeto,
      status_projeto,
      valor_contratado,
      valor_executado_2013_2020,
      nome_agente_financiador,
      natureza_agente_financiador,
      modalidade_financiamento,
      nome_agente_executor,
      natureza_agente_executor,
      uf_ag_executor,
      regiao_ag_executor,
      natureza_financiamento,
      `p&d_ou_demonstracao`,
      valor_executado_2013,valor_executado_2014,
      valor_executado_2015,valor_executado_2016,
      valor_executado_2017, valor_executado_2018, valor_executado_2019   ,valor_executado_2020,
      motor,
      categorias)



  #write.csv(anel_pd, here::here("inst/intermediarias/aneel_interm_06_10_2021.csv"))



  anel_pd

}



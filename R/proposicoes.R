#' @title Fetches proposition from API using a query
#' @description Fetches information about law's projects, resolutions, provisional measures,
#' law amendments, opinions and all the other propositions types on the
#' Deputies' Chamber.
#' Several parameters can be used to select and filter the final result. By default, the function
#' returns all the proposition which were presented or had some situation change in the last
#' 15 days.
#' @param id Proposition's ID
#' @param siglaUfAutor State's abbreviation of the proposition's author
#' @param siglaTipo Proposition type (i.e., PEC, PL, PDC)
#' @param siglaPartidoAutor Party's abbreviation of the proposition's author
#' @param numero Proposition number
#' @param ano Proposition year
#' @param dataApresentacaoInicio Proposition's presentation starting date
#' @param dataApresentacaoFim Proposition's presentation end date
#' @param dataInicio Proposition's processing starting date
#' @param dataFim Proposition's processing end date
#' @param idAutor Author's ID
#' @param autor Author's name
#' @param codPartido Party code
#' @param itens Items quantity. '-1' returns all the propositions which had been processed
#' in the last 30 days
#' @return Dataframe containing information about the proposition.
#' @details Note that if you have the proposition's ID, it's not necessary to add any other parameter on the
#' function call. The call to this function using the proposition's ID returns more details than using the
#' others parameters. If you don't have the proposition's ID, the \code{\link[rcongresso]{fetch_id_proposicao}}
#' function may be helpful.
#' @examples
#' pec241 <- fetch_proposicao(id = 2088351)
#' pec241 <- fetch_proposicao(siglaTipo = "PEC", numero = 241, ano = 2016)
#' @seealso
#'  \code{\link[rcongresso]{fetch_tipo_proposicao}}, \code{\link[rcongresso]{fetch_id_proposicao}}
#' @rdname fetch_proposicao
#' @export
fetch_proposicao <- function(id = NULL, siglaUfAutor = NULL, siglaTipo = NULL,
                             siglaPartidoAutor = NULL, numero = NULL, ano = NULL,
                             dataApresentacaoInicio = NULL, dataApresentacaoFim = NULL,
                             dataInicio = NULL, dataFim = NULL, idAutor = NULL,
                             autor = NULL, codPartido = NULL, itens = NULL){

  parametros <- as.list(environment(), all=TRUE)

  if(!length(.verifica_parametros_entrada(parametros)))
    .congresso_api(.PROPOSICOES_PATH) %>%
    .assert_dataframe_completo(.COLNAMES_PROPOSICAO) %>%
    .coerce_types(.COLNAMES_PROPOSICAO)
  else if(is.null(id))
    .fetch_using_queries(parametros, .PROPOSICOES_PATH)%>%
    .assert_dataframe_completo(.COLNAMES_PROPOSICAO) %>%
    .coerce_types(.COLNAMES_PROPOSICAO)
  else
    .fetch_using_id(id, .PROPOSICOES_PATH)%>%
    .assert_dataframe_completo(.COLNAMES_PROPOSICAO_POR_ID) %>%
    .coerce_types(.COLNAMES_PROPOSICAO_POR_ID)
}

#' @title Fetches all the votings which a proposition went through
#' @description Returns all the votings related to a proposition by its id.
#' @param id_prop Proposition's ID
#' @return Dataframe containing all the votings.
#' @examples
#' votacoes_pec241 <- fetch_votacoes(2088351)
#' @seealso
#'   \code{\link[rcongresso]{fetch_id_proposicao}}, \code{\link[rcongresso]{fetch_proposicao_from_votacao}}
#' @rdname fetch_votacoes
#' @export
fetch_votacoes <- function(id_prop){
  id <- NULL
  tibble::tibble(id = id_prop) %>%
    dplyr::mutate(path = paste0(.PROPOSICOES_PATH, "/", id, "/votacoes")) %>%
    dplyr::rowwise() %>%
    dplyr::do(
      .congresso_api(.$path)
    ) %>%
    dplyr::ungroup() %>%
    .assert_dataframe_completo(.COLNAMES_VOTACOES) %>%
    .coerce_types(.COLNAMES_VOTACOES)
}

#' @title Retrieves the proposition ID from its type, number and year
#' @description The function can be used to fetch a vector of ids as well, in case of many propositions.
#' @param tipo Proposition type (i.e., PEC, PL, PDC)
#' @param numero Proposition number
#' @param ano Proposition year
#' @return Proposition's ID.
#' @examples
#' pec241_id <- fetch_id_proposicao("PEC", 241, 2016)
#' @seealso
#'   \code{\link[rcongresso]{fetch_id_partido}}
#' @rdname fetch_id_proposicao
#' @export
fetch_id_proposicao <- function(tipo, numero, ano){
  tibble::tibble(tipo, numero, ano) %>%
    dplyr::rowwise() %>%
    dplyr::do(
      .congresso_api(.PROPOSICOES_PATH,
                     list(siglaTipo = .$tipo, numero = .$numero, ano = .$ano,
                          ordem = "ASC", ordenarPor = "id", dataInicio = paste0(ano,"-01-01")))$id %>%
        .verifica_id(.WARNING_PROPOSICAO_ID) %>%
        .to_tibble()
    ) %>%
    unlist() %>%
    as.vector()
}

#' Fetches all the proposition types.
#'
#' @return Proposition types
#'
#' @examples
#' tipos_proposicao <- fetch_tipos_proposicao()
#'
#' @export
.fetch_tipos_proposicao <- function(){
  .congresso_api(.TIPOS_PROPOSICOES_PATH)
}

#' @title Fetches the type of the proposition from its id
#' @description Returns its id, abbreviation, name and description.
#' @param id_tipo_prop Proposition's type ID
#' @return Dataframe containing the proposition's type info.
#' @examples
#' tipo_prop129 <- fetch_tipo_proposicao(129)
#' @rdname fetch_tipo_proposicao
#' @export
fetch_tipo_proposicao <- function(id_tipo_prop){
  prop_types <- .fetch_tipos_proposicao() %>%
    dplyr::mutate(id = as.numeric(.$id))

  tibble::tibble(id = id_tipo_prop) %>%
    dplyr::left_join(prop_types, by = "id") %>%
    .assert_dataframe_completo(.COLNAMES_TIPO_PROPOSICAO) %>%
    .coerce_types(.COLNAMES_TIPO_PROPOSICAO)
}

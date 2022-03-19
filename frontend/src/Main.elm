module Main exposing (..)

import Bootstrap.CDN as CDN
import Bootstrap.General.HAlign as HAlign
import Bootstrap.Grid exposing (container)
import Bootstrap.ListGroup exposing (li, ul)
import Bootstrap.Pagination as Pagination
import Bootstrap.Spinner exposing (spinner)
import Browser
import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (classList)
import Http
import Json.Decode exposing (bool, field, list, map2, string)
import List exposing (concat, map, range)


endpoint : String
endpoint =
    "https://todo-list-6400.free.beeceptor.com"


getTodoList : Cmd Msg
getTodoList =
    Http.get
        { url = endpoint ++ "/api/v1/todo"
        , expect = Http.expectJson GotTodos (list (map2 TodoItem (field "description" string) (field "checked" bool)))
        }


type alias TodoItem =
    { description : String
    , checked : Bool
    }


type alias State =
    { todos : List TodoItem
    , page : Int
    , pageRange : ( Int, Int )
    , loading : Bool
    , error : Maybe Http.Error
    }


initState : State
initState =
    { todos = [], page = 1, pageRange = ( 1, 3 ), loading = True, error = Nothing }


main : Program () State Msg
main =
    Browser.element
        { init = \() -> ( initState, getTodoList )
        , subscriptions = \_ -> Sub.none
        , update = \msg model -> ( update msg model, Cmd.none )
        , view = view
        }


type Msg
    = OpenPage Int
    | Toggle
    | GotTodos (Result Http.Error (List TodoItem))


update : Msg -> State -> State
update msg model =
    case msg of
        OpenPage page ->
            { model | page = page }

        Toggle ->
            model

        GotTodos response ->
            case response of
                Ok todos ->
                    { model | todos = todos, loading = False }

                Err err ->
                    { model | error = Just err, loading = False }


view : State -> Html Msg
view model =
    container []
        (concat
            [ [ CDN.stylesheet
              , h1 [] [ text "My Todo List" ]
              , if not model.loading then
                    todoListView model.todos

                else
                    loadingView
              , paginationView model.page model.pageRange
              ]
            , case model.error of
                Nothing ->
                    []

                Just err ->
                    [ div [] [ text ("Error: " ++ httpErrorToString err) ] ]
            ]
        )


httpErrorToString : Http.Error -> String
httpErrorToString error =
    case error of
        Http.BadUrl url ->
            "The URL " ++ url ++ " was invalid"

        Http.Timeout ->
            "Timeout occurred connecting to the server"

        Http.NetworkError ->
            "Unable to reach the server"

        Http.BadStatus 500 ->
            "The server had a problem"

        Http.BadStatus 400 ->
            "Failed to authenticate, try logging in again"

        Http.BadStatus _ ->
            "Unknown error"

        Http.BadBody text ->
            "Unable to decode response from server: " ++ text


loadingView : Html Msg
loadingView =
    div [ classList [ ( "d-flex", True ), ( "justify-content-center", True ) ] ] [ spinner [] [] ]


todoListView : List TodoItem -> Html Msg
todoListView todos =
    ul (map todoView todos)


todoView : TodoItem -> Bootstrap.ListGroup.Item msg
todoView todo =
    li
        (if todo.checked then
            [ Bootstrap.ListGroup.success ]

         else
            []
        )
        [ text todo.description
        ]


paginationView : Int -> ( Int, Int ) -> Html Msg
paginationView currentPage ( firstPage, finalPage ) =
    Pagination.defaultConfig
        |> Pagination.ariaLabel "Pagination"
        |> Pagination.align HAlign.centerXs
        |> Pagination.attrs []
        |> Pagination.itemsList
            { selectedMsg = \idx -> OpenPage (idx + 1)
            , prevItem = Just <| Pagination.ListItem [] [ text "Previous" ]
            , nextItem = Just <| Pagination.ListItem [] [ text "Next" ]
            , activeIdx = currentPage - 1
            , data = range firstPage finalPage
            , itemFn = \idx _ -> Pagination.ListItem [] [ text <| String.fromInt (idx + 1) ]
            , urlFn = \idx _ -> "#" ++ String.fromInt (idx + 1)
            }
        |> Pagination.view

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
import Json.Decode exposing (Decoder, bool, field, list, map2, string)
import List exposing (map, range)


endpoint : String
endpoint =
    "https://todo-list-6400.free.beeceptor.com"


type alias TodoItem =
    { description : String
    , checked : Bool
    }


decodeTodoList : Decoder (List TodoItem)
decodeTodoList =
    list
        (map2 TodoItem
            (field "description" string)
            (field "checked" bool)
        )


getTodoList : Cmd Msg
getTodoList =
    Http.get
        { url = endpoint ++ "/api/v1/todo"
        , expect = Http.expectJson GotTodos decodeTodoList
        }


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
            "Got a 400 bad request error"

        Http.BadStatus _ ->
            "Unknown error"

        Http.BadBody text ->
            "Unable to decode response from server: " ++ text


type alias State =
    { todos : List TodoItem -- loaded list of todo
    , page : Int -- dynamic page number, updated by pagination UI
    , pageRange : ( Int, Int ) -- somehow needs to get loaded by API
    , loading : Bool
    , error : Maybe Http.Error -- errors that can come from the server
    }


initState : State
initState =
    { todos = []
    , page = 1
    , pageRange = ( 1, 1 )
    , loading = True
    , error = Nothing
    }


main : Program () State Msg
main =
    Browser.element
        { init = \() -> ( initState, getTodoList )
        , subscriptions = \_ -> Sub.none
        , update = \msg model -> ( update msg model, Cmd.none )
        , view = view
        }


type Msg
    = OpenPage Int -- swap page - triggered by pagination UI
    | GotTodos (Result Http.Error (List TodoItem)) -- recieved todo list from server


update : Msg -> State -> State
update msg model =
    case msg of
        OpenPage page ->
            { model | page = page }

        GotTodos response ->
            case response of
                Ok todos ->
                    { model | todos = todos, loading = False }

                Err err ->
                    { model | error = Just err, loading = False }


view : State -> Html Msg
view model =
    container []
        [ CDN.stylesheet
        , h1 [] [ text "My Todo List" ]
        , bodyView model
        , paginationView model.page model.pageRange
        , maybeErrorView model.error
        ]


maybeErrorView : Maybe Http.Error -> Html Msg
maybeErrorView error =
    div []
        (case error of
            Nothing ->
                []

            Just err ->
                [ text (httpErrorToString err) ]
        )


loadingView : Html Msg
loadingView =
    div
        [ classList [ ( "d-flex", True ), ( "justify-content-center", True ) ] ]
        [ spinner [] [] ]


bodyView : State -> Html Msg
bodyView model =
    if not model.loading then
        todoListView model.todos

    else
        loadingView


todoListView : List TodoItem -> Html Msg
todoListView todos =
    ul (map todoItemView todos)


todoItemView : TodoItem -> Bootstrap.ListGroup.Item msg
todoItemView todo =
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

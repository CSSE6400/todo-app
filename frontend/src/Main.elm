module Main exposing (..)

import Bootstrap.CDN as CDN
import Bootstrap.General.HAlign as HAlign
import Bootstrap.Grid exposing (container)
import Bootstrap.Form.Input as Input
import Bootstrap.ListGroup exposing (li, ul)
import Bootstrap.Pagination as Pagination
import Bootstrap.Spinner exposing (spinner)
import Bootstrap.Button exposing (button)
import Bootstrap.Modal as Modal
import Bootstrap.Button as Button
import Browser
import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (classList)
import Http
import Json.Decode exposing (Decoder, bool, field, int, list, map2, map3, string)
import List exposing (map, range)
import Html.Attributes exposing (class)
import Html.Attributes exposing (style)
import Json.Encode as Encode
import Html.Events exposing (onClick)


endpoint : String
endpoint =
    "http://localhost:8000"


type alias TodoItem =
    { description : String
    , checked : Bool
    }


decodeTodoItem : Decoder TodoItem
decodeTodoItem =
    map2 TodoItem
        (field "description" string)
        (field "checked" bool)

decodeTodoList : Decoder (List TodoItem)
decodeTodoList =
    list decodeTodoItem


type alias TodoListResponse =
    { data : List TodoItem
    , current_page : Int
    , last_page : Int
    }


decodeListResponse : Decoder TodoListResponse
decodeListResponse =
    map3 TodoListResponse
        (field "data" decodeTodoList)
        (field "current_page" int)
        (field "last_page" int)


getTodoList : Cmd Msg
getTodoList =
    Http.get
        { url = endpoint ++ "/api/v1/todo"
        , expect = Http.expectJson GotTodos decodeListResponse
        }

postTodoItem : String -> Cmd Msg
postTodoItem description =
    Http.post
        { url = endpoint ++ "/api/v1/todo"
        , body = Http.jsonBody (Encode.object
            [ ( "description", Encode.string description )
            , ( "checked", Encode.bool False )
            ])
        , expect = Http.expectJson TodoCreated decodeTodoItem
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


type alias Modal =
    { isOpen : Bool
    , description : String
    }

type alias State =
    { todos : List TodoItem -- loaded list of todo
    , page : Int -- dynamic page number, updated by pagination UI
    , pageRange : ( Int, Int ) -- somehow needs to get loaded by API
    , loading : Bool
    , error : Maybe Http.Error -- errors that can come from the server
    , modal : Modal
    }


initState : State
initState =
    { todos = []
    , page = 1
    , pageRange = ( 1, 1 )
    , loading = True
    , error = Nothing
    , modal = { isOpen = False, description = "" }
    }


main : Program () State Msg
main =
    Browser.element
        { init = \() -> ( initState, getTodoList )
        , subscriptions = \_ -> Sub.none
        , update = \msg model -> update msg model
        , view = view
        }


type Msg
    = OpenPage Int -- swap page - triggered by pagination UI
    | GotTodos (Result Http.Error TodoListResponse) -- recieved todo list from server
    | TodoCreated (Result Http.Error TodoItem) -- recieved newly created todo from server
    | OpenModal
    | CloseModal
    | UpdateInput String -- triggered by modal input
    | CreateTodo -- triggered by modal create button


-- update : Msg -> State -> State
update : Msg -> State -> (State, Cmd Msg)
update msg model =
    case msg of
        OpenPage page ->
            ({ model | page = page }, Cmd.none)

        GotTodos response ->
            case response of
                Ok todos ->
                    ({ model
                        | todos = todos.data
                        , page = todos.current_page
                        , pageRange = ( 1, todos.last_page )
                        , loading = False
                    }, Cmd.none)

                Err err ->
                    ({ model | error = Just err, loading = False }, Cmd.none)

        OpenModal ->
            ({ model | modal = { isOpen = True, description = "" } }, Cmd.none)

        CloseModal ->
            ({ model | modal = { isOpen = False, description = "" } }, Cmd.none)

        UpdateInput description ->
            ({ model | modal = { isOpen = True, description = description } }, Cmd.none)

        TodoCreated response ->
            case response of
                Ok todo ->
                    ({model | loading = False, todos = List.concat [model.todos, [todo]] }, Cmd.none)

                Err err ->
                    ({ model | error = Just err, loading = False }, Cmd.none)

        CreateTodo ->
            ({ model | loading = True }, postTodoItem model.modal.description)


view : State -> Html Msg
view model =
    container []
        [ CDN.stylesheet
        , CDN.fontAwesome
        , h1 [] [ text "My Todo List" ]
        , div [style "float" "right"] [button [Button.onClick OpenModal] [Html.i [class "fa fa-plus-circle"] []]]
        , bodyView model
        , paginationView model.page model.pageRange
        , maybeErrorView model.error
        , maybeModalView model.modal
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

maybeModalView : Modal -> Html Msg
maybeModalView modal =
    Modal.config CloseModal
            |> Modal.small
            |> Modal.h5 [] [ text "New Todo" ]
            |> Modal.body []
                [ Input.text
                    [ Input.id "myinput"
                    , Input.small
                    , Input.onInput UpdateInput
                    ]
                ]
            |> Modal.footer []
                [ Button.button
                    [ Button.primary
                    , Button.attrs [ onClick CreateTodo ]
                    ]
                    [ text "Submit" ]
                ]
            |> Modal.view (if modal.isOpen then Modal.shown else Modal.hidden)

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

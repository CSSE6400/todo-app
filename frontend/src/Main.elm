module Main exposing (..)

import Bootstrap.Button as Button exposing (button)
import Bootstrap.CDN as CDN
import Bootstrap.Form.Input as Input
import Bootstrap.General.HAlign as HAlign
import Bootstrap.Grid exposing (container)
import Bootstrap.ListGroup as ListGroup
import Bootstrap.Modal as Modal
import Bootstrap.Pagination as Pagination
import Bootstrap.Spinner exposing (spinner)
import Browser
import Html exposing (Html, div, h1, text)
import Html.Attributes exposing (class, classList, style)
import Html.Events exposing (onClick)
import Http
import Json.Decode exposing (Decoder, bool, field, int, list, map2, map3, string)
import Json.Encode as Encode
import List exposing (map, range)


endpoint : String
endpoint =
    "http://localhost:8000"


type alias TodoItem =
    { id : Int
    , description : String
    , checked : Bool
    }


decodeTodoItem : Decoder TodoItem
decodeTodoItem =
    map3 TodoItem
        (field "id" int)
        (field "description" string)
        (field "checked" bool)


encodeTodoItem : TodoItem -> Encode.Value
encodeTodoItem todo =
    Encode.object
        [ ( "id", Encode.int todo.id )
        , ( "description", Encode.string todo.description )
        , ( "checked", Encode.bool todo.checked )
        ]


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


getTodoList : Int -> Cmd Msg
getTodoList page =
    Http.get
        { url = endpoint ++ "/api/v1/todo?page=" ++ (String.fromInt page)
        , expect = Http.expectJson GotTodos decodeListResponse
        }


postTodoItem : String -> Cmd Msg
postTodoItem description =
    Http.post
        { url = endpoint ++ "/api/v1/todo"
        , body =
            Http.jsonBody
                (Encode.object
                    [ ( "description", Encode.string description )
                    , ( "checked", Encode.bool False )
                    ]
                )
        , expect = Http.expectJson TodoUpdated decodeTodoItem
        }


putTodoItem : TodoItem -> Cmd Msg
putTodoItem todo =
    Http.request
        { method = "PUT"
        , headers = []
        , url = endpoint ++ "/api/v1/todo/" ++ String.fromInt todo.id
        , body = Http.jsonBody (encodeTodoItem todo)
        , expect = Http.expectJson TodoUpdated decodeTodoItem
        , timeout = Nothing
        , tracker = Nothing
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
        { init = \() -> ( initState, getTodoList 1 )
        , subscriptions = \_ -> Sub.none
        , update = \msg model -> update msg model
        , view = view
        }


type Msg
    = OpenPage Int -- swap page - triggered by pagination UI
    | GotTodos (Result Http.Error TodoListResponse) -- recieved todo list from server
    | TodoUpdated (Result Http.Error TodoItem) -- recieved newly created or modified todo from server
    | OpenModal
    | CloseModal
    | UpdateInput String -- triggered by modal input
    | CreateTodo -- triggered by modal create button
    | TickTodo TodoItem -- triggered clicking a todo



-- if todo with given id is found, update in place, otherwise append todo item to list
updateTodos : List TodoItem -> TodoItem -> List TodoItem
updateTodos todos todo =
    case List.head (List.filter (\t -> t.id == todo.id) todos) of
        Just _ ->
            List.map
                (\t ->
                    if t.id == todo.id then
                        todo

                    else
                        t
                )
                todos

        Nothing ->
            todos ++ [ todo ]



-- update : Msg -> State -> State


update : Msg -> State -> ( State, Cmd Msg )
update msg model =
    case msg of
        OpenPage page ->
            ( { model | page = page }, getTodoList page )

        GotTodos response ->
            case response of
                Ok todos ->
                    ( { model
                        | todos = todos.data
                        , page = todos.current_page
                        , pageRange = ( 1, todos.last_page )
                        , loading = False
                      }
                    , Cmd.none
                    )

                Err err ->
                    ( { model | error = Just err, loading = False }, Cmd.none )

        OpenModal ->
            ( { model | modal = { isOpen = True, description = "" } }, Cmd.none )

        CloseModal ->
            ( { model | modal = { isOpen = False, description = "" } }, Cmd.none )

        UpdateInput description ->
            ( { model | modal = { isOpen = True, description = description } }, Cmd.none )

        TodoUpdated response ->
            case response of
                Ok todo ->
                    ( { model | loading = False, todos = updateTodos model.todos todo }, Cmd.none )

                Err err ->
                    ( { model | error = Just err, loading = False }, Cmd.none )

        CreateTodo ->
            ( { model | loading = True }, postTodoItem model.modal.description )

        TickTodo todo ->
            ( model, putTodoItem { todo | checked = not todo.checked } )


view : State -> Html Msg
view model =
    container []
        [ CDN.stylesheet
        , CDN.fontAwesome
        , h1 [] [ text "My Todo List" ]
        , div [ style "float" "right" ] [ button [ Button.onClick OpenModal ] [ Html.i [ class "fa fa-plus-circle" ] [] ] ]
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
        |> Modal.view
            (if modal.isOpen then
                Modal.shown

             else
                Modal.hidden
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
    ListGroup.custom (map todoItemView todos)


todoItemView : TodoItem -> ListGroup.CustomItem Msg
todoItemView todo =
    ListGroup.button
        ((if todo.checked then
            [ ListGroup.success ]

          else
            []
         )
            ++ [ ListGroup.attrs [ onClick (TickTodo todo) ] ]
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

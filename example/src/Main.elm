module Main exposing (main)

import Browser
import Html exposing (Html, text)


main : Program () Model Msg
main =
    Browser.element
        { init = always ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = always Sub.none
        }



-- MODEL


type alias Model =
    ()


initialModel : Model
initialModel =
    ()



-- UPDATE


type alias Msg =
    ()


update : Msg -> Model -> ( Model, Cmd Msg )
update _ m =
    ( m, Cmd.none )



-- VIEW


view : Model -> Html Msg
view _ =
    text "Hello World"

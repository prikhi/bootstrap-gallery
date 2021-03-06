module BootstrapGallery exposing
    ( Config
    , Model, initial
    , modal, thumbnails, openOnClick
    , Msg, update, subscriptions, open, close, next, previous
    )

{-| This module is used to render images as gallery thumbnails & lightboxes.


# Configuration

@docs Config


# Data

@docs Model, initial


# Rendering

@docs modal, thumbnails, openOnClick


# Updating

@docs Msg, update, subscriptions, open, close, next, previous

-}

import Animation
import Html exposing (Html, a, div, img, text)
import Html.Attributes exposing (class, href, src, tabindex)
import Html.Events exposing (custom, keyCode, preventDefaultOn, stopPropagationOn)
import Html.Keyed as Keyed
import Json.Decode as Decode
import Time exposing (millisToPosix)


{-| Configuration for pulling the thumbnail & image URLs out of an arbitrary
image type.
-}
type alias Config a =
    { thumbnailUrl : a -> Maybe String
    , imageUrl : a -> String
    }


{-| The internal state of the Gallery.
-}
type alias Model a =
    { data : Maybe (SubModel a)
    , style : Animation.State
    , foregroundImageStyle : Animation.State
    , backgroundImageStyle : Animation.State
    }


{-| A sub-state for a shown gallery modal.
-}
type alias SubModel a =
    { selected : a
    , next : a
    , previous : a
    }


{-| A blank gallery with no associated images.
-}
initial : Model a
initial =
    { data = Nothing
    , style =
        Animation.style
            [ Animation.opacity 0
            , Animation.display Animation.none
            ]
    , foregroundImageStyle = Animation.style [ Animation.opacity 0 ]
    , backgroundImageStyle = Animation.style []
    }


{-| Messages the modal may raise.
-}
type Msg a
    = Noop
    | Close
    | Select a
    | Next
    | Previous
    | Animate Animation.Msg


{-| Update the Gallery model.
-}
update : Config a -> Msg a -> Model a -> List a -> Model a
update cfg msg m l =
    case msg of
        Noop ->
            m

        Close ->
            let
                newStyle =
                    Animation.interrupt
                        [ Animation.to
                            [ Animation.opacity 0 ]
                        , Animation.set
                            [ Animation.display Animation.none ]
                        ]
                        m.style
            in
            { m | style = newStyle }

        Select s ->
            let
                newStyle =
                    Animation.interrupt
                        [ Animation.set
                            [ Animation.display Animation.flex ]
                        , Animation.to
                            [ Animation.opacity 1 ]
                        ]
                        m.style
            in
            updateSelectedItem cfg l (always <| Just s) m
                |> (\model -> { model | style = newStyle })

        Next ->
            updateSelectedItem cfg l (Maybe.map .next) m

        Previous ->
            updateSelectedItem cfg l (Maybe.map .previous) m

        Animate animateMsg ->
            { m
                | style = Animation.update animateMsg m.style
                , foregroundImageStyle = Animation.update animateMsg m.foregroundImageStyle
                , backgroundImageStyle = Animation.update animateMsg m.backgroundImageStyle
            }


{-| Transition the background image & then build a new submodel by using the
given image selector function.
-}
updateSelectedItem : Config a -> List a -> (Maybe (SubModel a) -> Maybe a) -> Model a -> Model a
updateSelectedItem cfg l selector m =
    let
        newData model =
            selector model.data
                |> Maybe.andThen (calcNextPrev l)
    in
    m
        |> updateBackgroundImage cfg selector
        |> (\model -> { model | data = newData model })


{-| Transition the background image styles using the given selector function.
-}
updateBackgroundImage : Config a -> (Maybe (SubModel a) -> Maybe a) -> Model a -> Model a
updateBackgroundImage cfg selector m =
    let
        backgroundImageProperty image =
            Animation.exactly "background-image" <|
                String.concat
                    [ "url('", cfg.imageUrl image, "')" ]

        noTransition image =
            ( Animation.interrupt
                [ Animation.set [ backgroundImageProperty image ]
                ]
                m.backgroundImageStyle
            , Animation.interrupt
                [ Animation.set [ Animation.opacity 0 ] ]
                m.foregroundImageStyle
            )

        ( bgStyle, fgStyle ) =
            case ( Maybe.map .selected m.data, selector m.data ) of
                ( Just selected, Just new ) ->
                    ( Animation.queue
                        [ Animation.set [ backgroundImageProperty selected ] ]
                        m.backgroundImageStyle
                    , Animation.queue
                        [ Animation.wait (millisToPosix 50)
                        , Animation.set
                            [ backgroundImageProperty new, Animation.opacity 0 ]
                        , Animation.to [ Animation.opacity 1 ]
                        ]
                        m.foregroundImageStyle
                    )

                ( Just selected, Nothing ) ->
                    noTransition selected

                ( Nothing, Just new ) ->
                    noTransition new

                ( Nothing, Nothing ) ->
                    ( m.backgroundImageStyle, m.foregroundImageStyle )
    in
    { m | foregroundImageStyle = fgStyle, backgroundImageStyle = bgStyle }


{-| Subscribe to the animation updates.
-}
subscriptions : Model a -> Sub (Msg a)
subscriptions m =
    Animation.subscription Animate
        [ m.style, m.backgroundImageStyle, m.foregroundImageStyle ]


{-| Build a Model with the correct Next & Previous fields for the selected item.
-}
calcNextPrev : List a -> a -> Maybe (SubModel a)
calcNextPrev allItems selected =
    let
        orMaybe mx my =
            case ( mx, my ) of
                ( Just _, _ ) ->
                    mx

                ( Nothing, Just _ ) ->
                    my

                ( Nothing, Nothing ) ->
                    Nothing
    in
    List.foldl
        (\i acc ->
            case acc of
                ( prev, True, Nothing ) ->
                    ( prev, True, Just i )

                ( _, True, Just _ ) ->
                    acc

                ( prev, False, next_ ) ->
                    if i == selected then
                        ( prev, True, next_ )

                    else
                        ( Just i, False, next_ )
        )
        ( Nothing, False, Nothing )
        allItems
        |> (\( p, _, n ) ->
                Maybe.map2 Tuple.pair
                    (orMaybe p
                        (List.drop (List.length allItems - 1) allItems
                            |> List.head
                        )
                    )
                    (orMaybe n
                        (List.head allItems)
                    )
                    |> Maybe.map
                        (\( previous_, next_ ) ->
                            { selected = selected
                            , next = next_
                            , previous = previous_
                            }
                        )
           )


{-| Render the Modal.

To get nice open/close transitions, you should always render the modal, even if
the Modal has not been opened.

Preferably place this at the end of your HTML to prevent other elements from
obscuring the modal while it transitions to the open state.

-}
modal : Model a -> Html (Msg a)
modal model =
    let
        previousElement data =
            if data.previous /= data.selected then
                Html.span [ class "modal-prev position-absolute d-flex align-items-center justify-content-center h-100", previousOnClick ]
                    [ Html.span [ class "fa-stack fa-2x" ]
                        [ Html.i [ class "fa fa-circle fa-stack-2x" ] []
                        , Html.i [ class "fa fa-chevron-left fa-stack-1x fa-inverse" ] []
                        ]
                    ]

            else
                text ""

        nextElement data =
            if data.next /= data.selected then
                Html.span [ class "modal-next position-absolute d-flex align-items-center justify-content-center h-100", nextOnClick ]
                    [ Html.span [ class "fa-stack fa-2x" ]
                        [ Html.i [ class "fa fa-circle fa-stack-2x" ] []
                        , Html.i [ class "fa fa-chevron-right fa-stack-1x fa-inverse" ] []
                        ]
                    ]

            else
                text ""

        ( modal_, backdrop ) =
            case model.data of
                Nothing ->
                    ( div
                        [ class "modal align-items-center justify-content-center"
                        , tabindex -1
                        ]
                        [ div [ class "modal-dialog position-absolute mt-0 mb-0" ]
                            [ div [ class "modal-content h-100 border-0 bg-transparent" ]
                                [ div [ class "modal-body" ]
                                    []
                                ]
                            ]
                        ]
                    , div [ class "modal-backdrop" ] []
                    )

                Just data ->
                    ( div
                        [ class "modal w-100 h-100 d-flex align-items-center justify-content-center"
                        , tabindex -1
                        , closeModalOnClick
                        , closeModalOnEsc
                        , ignoreScroll
                        , ignoreMove
                        ]
                        [ div
                            (class "modal-dialog position-absolute mt-0 mb-0 modal-dialog-background"
                                :: Animation.render model.backgroundImageStyle
                            )
                            []
                        , div
                            (class "modal-dialog position-absolute mt-0 mb-0 modal-dialog-foreground"
                                :: Animation.render model.foregroundImageStyle
                            )
                            []
                        , div [ class "modal-dialog position-absolute mt-0 mb-0" ]
                            [ div [ class "modal-content h-100 border-0 bg-transparent" ]
                                [ div [ ignoreClick, class "modal-body" ]
                                    [ previousElement data
                                    , nextElement data
                                    , Html.span [ class "fa-stack fa-2x modal-close", closeModalOnClick ]
                                        [ Html.i [ class "fa fa-circle fa-stack-2x" ] []
                                        , Html.i [ class "fa fa-times fa-stack-1x fa-inverse" ] []
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    , div [ class "modal-backdrop w-100 h-100 d-flex", closeModalOnClick ] []
                    )
    in
    Keyed.node "div"
        (class "gallery-modal" :: Animation.render model.style)
        [ ( "gallery-modal", modal_ ), ( "gallery-backdrop", backdrop ) ]


{-| Render thumbnails in a column grid using the given list of images.
-}
thumbnails : Config a -> List a -> Html (Msg a)
thumbnails c =
    let
        renderItem item =
            div [ class "col-6 col-md-4 col-lg-3 mb-2 text-center" ]
                [ a
                    [ href <| c.imageUrl item
                    , openModalOnClick item
                    ]
                    [ img
                        [ class "img-thumbnail"
                        , src <| Maybe.withDefault (c.imageUrl item) <| c.thumbnailUrl item
                        ]
                        []
                    ]
                ]
    in
    div [ class "row justify-content-around align-items-center" ] << List.map renderItem


{-| Open the modal & select the given item.
-}
open : Config a -> Model a -> List a -> a -> Model a
open cfg model items item =
    update cfg (Select item) model items


{-| Close the modal.
-}
close : Config a -> Model a -> List a -> Model a
close cfg =
    update cfg Close


{-| Select the next item in the list.
-}
next : Config a -> Model a -> List a -> Model a
next cfg =
    update cfg Next


{-| Select the previous item in the list.
-}
previous : Config a -> Model a -> List a -> Model a
previous cfg =
    update cfg Previous


{-| Open the modal when the element is clicked & select the given item.
-}
openOnClick : (Msg a -> msg) -> a -> Html.Attribute msg
openOnClick m =
    Html.Attributes.map m << openModalOnClick



-- Helper Events


ignoreScroll : Html.Attribute (Msg a)
ignoreScroll =
    ignoreOn "wheel"


ignoreMove : Html.Attribute (Msg a)
ignoreMove =
    ignoreOn "touchmove"


ignoreClick : Html.Attribute (Msg a)
ignoreClick =
    ignoreOn "click"


ignoreOn : String -> Html.Attribute (Msg a)
ignoreOn event =
    custom event <|
        Decode.succeed
            { message = Noop
            , stopPropagation = True
            , preventDefault = True
            }


nextOnClick : Html.Attribute (Msg a)
nextOnClick =
    alwaysStopPropagationOn "click" Next


previousOnClick : Html.Attribute (Msg a)
previousOnClick =
    alwaysStopPropagationOn "click" Previous


closeModalOnEsc : Html.Attribute (Msg a)
closeModalOnEsc =
    stopPropagationOn "keyup" <|
        Decode.map (\msg -> ( msg, True )) <|
            (keyCode
                |> Decode.andThen
                    (\code ->
                        if code == 27 then
                            Decode.succeed Close

                        else
                            Decode.fail "Not ESC"
                    )
            )


closeModalOnClick : Html.Attribute (Msg a)
closeModalOnClick =
    alwaysStopPropagationOn "click" Close


openModalOnClick : a -> Html.Attribute (Msg a)
openModalOnClick =
    preventDefaultOn "click"
        << (\m -> Decode.succeed ( m, True ))
        << Select


alwaysStopPropagationOn : String -> msg -> Html.Attribute msg
alwaysStopPropagationOn event msg =
    Decode.succeed ( msg, True )
        |> stopPropagationOn event

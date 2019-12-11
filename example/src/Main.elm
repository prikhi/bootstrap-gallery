module Main exposing (main)

import BootstrapGallery as Gallery
import Browser
import Html exposing (Html, div, h1, h2, img, text)
import Html.Attributes exposing (class, src)


main : Program () Model Msg
main =
    Browser.element
        { init = always ( initialModel, Cmd.none )
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { lightboxModel : Gallery.Model Image
    , galleryModel : Gallery.Model Image
    }


initialModel : Model
initialModel =
    { lightboxModel = Gallery.initial
    , galleryModel = Gallery.initial
    }


type alias Image =
    String


imageGalleryConfig : Gallery.Config Image
imageGalleryConfig =
    { thumbnailUrl = Just
    , imageUrl = identity
    }



-- UPDATE


type Msg
    = LightboxMsg (Gallery.Msg Image)
    | GalleryMsg (Gallery.Msg Image)


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Sub.map LightboxMsg (Gallery.subscriptions model.lightboxModel)
        , Sub.map GalleryMsg (Gallery.subscriptions model.galleryModel)
        ]


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LightboxMsg subMsg ->
            Gallery.update imageGalleryConfig subMsg model.lightboxModel [ lightboxImage ]
                |> noCommand
                |> Tuple.mapFirst (\m -> { model | lightboxModel = m })

        GalleryMsg subMsg ->
            Gallery.update imageGalleryConfig subMsg model.galleryModel galleryImages
                |> noCommand
                |> Tuple.mapFirst (\m -> { model | galleryModel = m })


noCommand : a -> ( a, Cmd b )
noCommand m =
    ( m, Cmd.none )



-- VIEW


lightboxImage : Image
lightboxImage =
    "http://placekitten.com/2560/1440"


galleryImages : List Image
galleryImages =
    List.map (\s -> "http://placekitten.com/" ++ s)
        [ "2000/2000"
        , "2000/1000"
        , "1000/2000"
        , "2560/1440"
        ]


view : Model -> Html Msg
view model =
    div [ class "container" ]
        [ h1 [] [ text "Bootstrap Gallery Example" ]
        , div [ class "mt-4" ]
            [ h2 [] [ text "Lightbox" ]
            , div [ Gallery.open LightboxMsg lightboxImage ]
                [ img [ src lightboxImage, class "img-fluid" ] []
                ]
            ]
        , div [ class "mt-4" ]
            [ h2 [] [ text "Gallery" ]
            , Html.map GalleryMsg <| Gallery.thumbnails imageGalleryConfig galleryImages
            ]
        , Html.map LightboxMsg <| Gallery.modal model.lightboxModel
        , Html.map GalleryMsg <| Gallery.modal model.galleryModel
        ]

port module Main exposing (..)

import Html exposing (Html, text, div, h1, img)
import Html.Attributes exposing (src, width, height, style)
import Math.Matrix4 as Mat4 exposing (Mat4, makePerspective, makeLookAt, makeTranslate)
import Math.Vector3 as Vec3 exposing (Vec3, vec3)
import Math.Vector2 as Vec2 exposing (Vec2, vec2)

import WebGL exposing (..)

type alias Point3D = {x : Float, y : Float, z : Float}
type alias Polygons = List { normal : Point3D, vertices : List Point3D }


port polygon :  (Polygons -> msg) -> Sub msg

---- MODEL ----


type alias Model =
    { polygons : Polygons }


init : ( Model, Cmd Msg )
init =
    ( {polygons = [] }, Cmd.none )



---- UPDATE ----


type Msg
    = ReadPolygons Polygons



omikujiMesh : Polygons -> Mesh { position : Vec3, textureCoord : Vec2 }
omikujiMesh polygons =
    polygons
        |> List.map (\v -> v.vertices)
        |> List.map (List.map (\vertex -> vec3 vertex.x vertex.y vertex.z))
        |> List.map (\vertices ->
                         case vertices of
                             v1::v2::v3::[] -> ({position = v1,  textureCoord = vec2 0.0 0.0},
                                                {position = v2,  textureCoord = vec2 1.0 0.0},
                                                {position = v3,  textureCoord = vec2 0.0 1.0})
                             _ -> ({ position = Vec3.i,
                                     textureCoord = vec2 0.0 0.0
                                   } ,
                                       {position =Vec3.j,
                                        textureCoord = vec2 0.0 1.0
                                       },
                                       {position =Vec3.k,
                                        textureCoord = vec2 1.0 0.0
                                       })
                    )
        |> triangles



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReadPolygons polygons ->
            ( { model | polygons = polygons }, Cmd.none ) 


subscriptions model = polygon ReadPolygons

---- VIEW ----


view : Model -> Html Msg
view model =
    WebGL.toHtml
        [ width 400
        , height 400
        , style [ ( "display", "block" ) ]
        ]
    [ WebGL.entity
          vertexShader
          fragmentShader
          (omikujiMesh model.polygons)
          { world = Mat4.makeTranslate3 0 0 000,
            perspective = Mat4.makePerspective 60 1 100 1000,
            camera = Mat4.makeLookAt (vec3 100 500 500) (vec3 0 0 0) (Vec3.j)
          }
    ]
    
    
---- PROGRAM ----


main : Program Never Model Msg
main =
    Html.program
        { view = view
        , init = init
        , update = update
        , subscriptions =
            subscriptions
        }




vertexShader : Shader
               { position : Vec3, textureCoord : Vec2 }
               { world : Mat4,
                 perspective : Mat4,
                 camera : Mat4
               }
               { vcolor : Vec3, vTextureCoord : Vec2 }
vertexShader =
    [glsl|
        attribute vec3 position;
        attribute vec2 textureCoord;
        uniform mat4 world;
        uniform mat4 perspective;
        uniform mat4 camera;
        varying vec3 vcolor;
        varying vec2 vTextureCoord;

        void main() {
                gl_Position = perspective * camera * world * vec4(position, 1.0);
                vcolor = position / 100.0;
                vTextureCoord = textureCoord;
        }
    |]


fragmentShader : Shader {  }
               { world : Mat4,
                 perspective : Mat4,
                 camera : Mat4
               } { vcolor : Vec3, vTextureCoord : Vec2 }
fragmentShader =
    [glsl|
        precision mediump float;
        varying vec3 vcolor;
        varying vec2 vTextureCoord;

        void main () {
                if( vTextureCoord.x <= 0.1 || vTextureCoord.x >= 0.9 || vTextureCoord.y <= 0.1 || vTextureCoord.y >= 0.9 ){
                        gl_FragColor = vec4(vcolor, 1.0);
                    } else {
                          gl_FragColor = vec4(0.0);
                      }
        }
    |]

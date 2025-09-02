use <deps/Round_Anything/polyround.scad>;

// gen_coords generates polyRound coordinates given [x, y, r?] coordinates
// if r is not supplied, it is defaulted to 0.
// this will typically be used as `linear_extrude() { polygon(gen_coords); };`
function gen_coords(
    points,
    fn = 5,
) = 
  let (
    radii_points = [ for (point = points) [point.x, point.y, len(point) > 2 ? point.z : 0]]
  )
  polyRound(radii_points, fn=fn, mode=0);

// translate_coords translates 2D coords in the XY plane, allowing rotation about the Z axis
// uses translateRadiiPoints under the hood, requires coords, not points ([x, y, r])
// translation is a vector of [x, y] for the translation
// rotation is an angle (in degrees) to rotate a about the Z axis
function translate_coords(
    coords,
    translation,
    rotation,
) = 
    translateRadiiPoints(coords, translation, rotation);

// extrude extrudes a 2D shape into the 3rd dimension of the given plane
// `length` is the length to extrude from into the given `plane`
// `plane` is the plane to extrude into. default is `Z`. possible values are `X`, `-X`, `Y`, `-Y`, `Z`, `-Z`
// a non-valid plane will error
// `center` indicates whether the extrusion should be from the center of the `plane`, or projecting into it.
// `convexity` changes the convexity of the underlying object. see https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Convexity_Affects_Rendering
// `twist` twists the part
// `slices` determines how many faces the twisted object will have
// the 2D shape to extrude should be provided as children
module extrude(
    length,
    plane = "Z",
    center = false,
    convexity=10, 
    twist=0, 
    slices=20,
) {
    assert(
        plane == "X" ||
        plane == "-X" ||
        plane == "Y" ||
        plane == "-Y" ||
        plane == "Z" ||
        plane == "-Z"
    )
    let (
        radii_points = [ 
            for (point = points) 
                [point.x, point.y, len(point) > 2 ? point.z : 0]
        ],
        translation = 
          plane == "X"
          ? [0,0,0]
          : plane == "-X"
          ? [ center ? 0: -length, 0, 0]
          : plane == "Y"
          ? [0, center ? 0 : length, 0]
          : plane == "-Y"
          ? [0, 0, 0]
          : plane == "-Z"
          ? [0, 0, center ? 0: -length]
          : [0, 0, 0],
        rotation = 
            plane == "X"
            ? [90, 0, 90]
            : plane == "-X"
            ? [90, 0, 90]
            : plane == "Y"
            ? [90, 0, 0]
            : plane == "-Y"
            ? [90, 0, 0]
            : plane == "-Z"
            ? [0, 0, 0]
            : [0, 0, 0]
    )

    translate(translation) {
        rotate(rotation) {
            linear_extrude(
                height = length, 
                center = center,
                convexity=convexity, 
                twist=twist, 
                slices=slices,
            ) {
                children();
            };
        }
    }
}


// extrude_coords extrudes coordinates using PolyRoundExtrude
// `points` are given coordinates of [x, y, r?] where `r` is a radius to extrude about the point
// if `r` is not supplied, 0 is assumed
// `length` is the length to extrude from [0, 0] into the given `plane`
// `plane` is the plane to extrude into. default is `Z`. possible values are `X`, `-X`, `Y`, `-Y`, `Z`, `-Z`
// a non-valid plane will error
// `center` indicates whether the extrusion should be from the center of the `plane`, or projecting into it.
// `r1` is the radius of the extrusion of the face which faces opposite of the extrusion plane
//     i.e.: if the extruding plane is `Z`, r1 will add a radius to the face in the `-Z`-most direction
// `r2` is the radius of the extrusion of the face which faces toward the extrusion plane
//     i.e.: if the extruding plane is `Z`, r2 will add a radius to the face in the `Z`-most direction
// `fn` determines how many faces to subdivide by, no different than $fn normally would
// `convexity` will set the convexity of the object. see https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Convexity_Affects_Rendering
module extrude_points(
    points,
    length,
    plane="Z",
    center=false,
    r1 = 0,
    r2 = 0,
    fn = 10,
    convexity = 10,
) {
    assert(
        plane == "X" ||
        plane == "-X" ||
        plane == "Y" ||
        plane == "-Y" ||
        plane == "Z" ||
        plane == "-Z"
    )
    let (
        radii_points = [ 
            for (point = points) 
                [point.x, point.y, len(point) > 2 ? point.z : 0]
        ],
        translation = 
          plane == "X"
          ? [0,0,0]
          : plane == "-X"
          ? [ center ? 0: -length, 0, 0]
          : plane == "Y"
          ? [0, center ? 0 : length, 0]
          : plane == "-Y"
          ? [0, 0, 0]
          : plane == "-Z"
          ? [0, 0, center ? 0: -length]
          : [0, 0, 0],
        rotation = 
            plane == "X"
            ? [90, 0, 90]
            : plane == "-X"
            ? [90, 0, 90]
            : plane == "Y"
            ? [90, 0, 0]
            : plane == "-Y"
            ? [90, 0, 0]
            : plane == "-Z"
            ? [0, 0, 0]
            : [0, 0, 0]
    )

    translate(translation) {
        rotate(rotation) {
            polyRoundExtrude(
                radii_points = radii_points,
                length=length,
                r1 = r1,
                r2 = r2,
                fn = fn,
                convexity = convexity,
            );
        }
    }
};

// extrude_shell_points generates a 3D object of a shell from the given points
// it can be given 2D children to fill the shell
// `points` are a set of [x, y, r?] coordinates for the shape of the shell
// `inner_offset` is the distance from the centerline of the coordinates to make the inner wall
// `outer_offset` is the distance form the centerline of the coordinates to make the outer wall
//     these can both be negative (meaning they will appear closer to the center of the points)
//         or positive (meaning they will appear farther from the center of the points)
//         or any combination between.
//     I don't know what happens if outer_offset is smaller than inner_offset,
// `length` is the length to extrude the shell into the given `plane`
// `plane` is the plane to extrude into
// `center` determines if the shape will center about the `plane`
// `r1` is the radius of the extrusion of the face which faces opposite of the extrusion plane
//     i.e.: if the extruding plane is `Z`, r1 will add a radius to the face in the `-Z`-most direction
// `r2` is the radius of the extrusion of the face which faces toward the extrusion plane
//     i.e.: if the extruding plane is `Z`, r2 will add a radius to the face in the `Z`-most direction
// `min_outer_radius` in the minimum outer radius of the shape
// `min_inner_radius` is the minimum inner radius of the shape 
// `fn` is the number of faces to use
module extrude_shell_points(
    points,
    inner_offset,
    outer_offset,
    length,
    plane = "Z",
    center = false,
    r1 = 0,
    r2 = 0,
    min_outer_radius = 0,
    min_inner_radius = 0,
    fn = 30,
) {
    assert(
        plane == "X" ||
        plane == "-X" ||
        plane == "Y" ||
        plane == "-Y" ||
        plane == "Z" ||
        plane == "-Z"
    )
    let (
        radii_points = [ 
            for (point = points) 
                [point.x, point.y, len(point) > 2 ? point.z : 0]
        ],
        translation = 
          plane == "X"
          ? [0,0,0]
          : plane == "-X"
          ? [ center ? -length/2: -length, 0, 0]
          : plane == "Y"
          ? [0, center ? length/2 : length, 0]
          : plane == "-Y"
          ? [0, 0, 0]
          : plane == "-Z"
          ? [0, 0, center ? -length/2: -length]
          : [0, 0, 0],
        rotation = 
            plane == "X"
            ? [90, 0, 90]
            : plane == "-X"
            ? [90, 0, 90]
            : plane == "Y"
            ? [90, 0, 0]
            : plane == "-Y"
            ? [90, 0, 0]
            : plane == "-Z"
            ? [0, 0, 0]
            : [0, 0, 0]
    );
    translate(translation) {
        rotate(rotation) {
            extrudeWithRadius(
                length=length,
                r1=r1,
                r2=r2,
                fn=fn,
            ) {
                shell2d(
                    offset1 = inner_offset,
                    offset2 = outer_offset,
                    minOr = min_outer_radius,
                    minIr = min_inner_radius,
                ) {
                    polyRound(radiiPoints=radii_points, fn=fn, mode=0);
                    children();
                }
            }
        }
    }
}

// extrude_beam extrudes a line into the given plane with the provided points
// `points` are a set of [x, y, r?] coordinates for the shape of the shell
// `inner_offset` is the distance from the centerline of the coordinates to make the inner wall
// `outer_offset` is the distance form the centerline of the coordinates to make the outer wall
//     these can both be negative (meaning they will appear closer to the center of the points)
//         or positive (meaning they will appear farther from the center of the points)
//         or any combination between.
//     I don't know what happens if outer_offset is smaller than inner_offset,
// `length` is the length to extrude the shell into the given `plane`
// `plane` is the plane to extrude into
// `startAngle` is the angle of the extrusion for the first point given,
//.    the angle it is relative to is determined by the `mode`
// `endAngle` is the angle of the extrusion at the last point given,
//.    the angle it is relative to is determined by the `mode`
// `mode` determine how `startAngle` and `endAngle` are used
//     mode=1 - include endpoints startAngle&2 are relative to the angle of the last two points and equal 90deg if not defined
//     mode=2 - Only the forward path is defined, useful for combining the beam with other radii points, see examples for a use-case.
//     mode=3 - include endpoints startAngle&2 are absolute from the x axis and are 0 if not defined
// `center` determines if the shape will center about the `plane`
// `r1` is the radius of the extrusion of the face which faces opposite of the extrusion plane
//     i.e.: if the extruding plane is `Z`, r1 will add a radius to the face in the `-Z`-most direction
// `r2` is the radius of the extrusion of the face which faces toward the extrusion plane
//     i.e.: if the extruding plane is `Z`, r2 will add a radius to the face in the `Z`-most direction
// `fn` is the number of faces to use
// `convexity` is the convexity of the underlying body
module extrude_beam(
    points,
    inner_offset,
    outer_offset,
    length,
    plane = "Z",
    startAngle = 90,
    endAngle = 90,
    mode = 0,
    center = false,
    r1 = 0,
    r2 = 0,
    fn = 30,
    convexity = 10,
) {
    assert(
        plane == "X" ||
        plane == "-X" ||
        plane == "Y" ||
        plane == "-Y" ||
        plane == "Z" ||
        plane == "-Z"
    )
    let (
        radii_points = [ 
            for (point = points) 
                [point.x, point.y, len(point) > 2 ? point.z : 0]
        ],
        translation = 
          plane == "X"
          ? [0,0,0]
          : plane == "-X"
          ? [ center ? -length/2: -length, 0, 0]
          : plane == "Y"
          ? [0, center ? length/2 : length, 0]
          : plane == "-Y"
          ? [0, 0, 0]
          : plane == "-Z"
          ? [0, 0, center ? -length/2: -length]
          : [0, 0, 0],
        rotation = 
            plane == "X"
            ? [90, 0, 90]
            : plane == "-X"
            ? [90, 0, 90]
            : plane == "Y"
            ? [90, 0, 0]
            : plane == "-Y"
            ? [90, 0, 0]
            : plane == "-Z"
            ? [0, 0, 0]
            : [0, 0, 0]
    );
    translate(translation) {
        rotate(rotation) {
            polyRoundExtrude(
                radiiPoints = beamChain(
                    radiiPoints=radii_points,
                    offset1 = inner_offset,
                    offset2 = outer_offset,
                ), 
                length = length, 
                r1 = r1, 
                r2 = r2, 
                fn = fn, 
                convexity = convexity,
            );
        }
    }
}
var xhr = new XMLHttpRequest();
xhr.open("GET", "omikuji.stl", true);
xhr.responseType = "arraybuffer";

xhr.onload = function(event){
    var arrayBuffer = xhr.response;
    console.log(arrayBuffer);
    var dataView = new DataView(arrayBuffer);
    var faces = dataView.getUint32( 80, true );

    var r, g, b, hasColors = false, colors;
		var defaultR, defaultG, defaultB, alpha;

		for ( var index = 0; index < 80 - 10; index ++ ) {

				if ( ( dataView.getUint32( index, false ) == 0x434F4C4F /*COLO*/ ) &&
					   ( dataView.getUint8( index + 4 ) == 0x52 /*'R'*/ ) &&
					   ( dataView.getUint8( index + 5 ) == 0x3D /*'='*/ ) ) {

					  hasColors = true;
					  colors = [];

					  defaultR = dataView.getUint8( index + 6 ) / 255;
					  defaultG = dataView.getUint8( index + 7 ) / 255;
					  defaultB = dataView.getUint8( index + 8 ) / 255;
					  alpha = dataView.getUint8( index + 9 ) / 255;
				}

		}

    var offset = 84;
		var faceLength = 12 * 4 + 2;

    var polygons = [];

    for(var face = 0; face < faces; face++ ) {
        var begin = offset + face * faceLength;
        var vertex1Begin = begin + 12;
        var vertex2Begin = vertex1Begin + 12;
        var vertex3Begin = vertex2Begin + 12;

        if( hasColors ){
            var packedColor = dataView.getUint16( begin + 48, true );

            if ( ( packedColor & 0x8000 ) === 0 ) {
                r = ( packedColor & 0x1F ) / 31;
                g = ( ( packedColor >> 5 ) & 0x1F ) / 31;
                b = ( ( packedColor >> 10 ) & 0x1F ) / 31;

            } else {
                r = defaultR;
                g = defaultG;
                b = defaultB;

            }

            var normal = {
                x : dataView.getFloat32(begin, true),
                y : dataView.getFloat32(begin + 4, true),
                z : dataView.getFloat32(begin + 8, true)
            };
        }


        var vertex1 = {
            x : dataView.getFloat32(vertex1Begin, true),
            y : dataView.getFloat32(vertex1Begin + 4, true),
            z : dataView.getFloat32(vertex1Begin + 8, true)
        };
        
        var vertex2 = {
            x : dataView.getFloat32(vertex2Begin, true),
            y : dataView.getFloat32(vertex2Begin + 4, true),
            z : dataView.getFloat32(vertex2Begin + 8, true)
        };

        var vertex3 = {
            x : dataView.getFloat32(vertex3Begin, true),
            y : dataView.getFloat32(vertex3Begin + 4, true),
            z : dataView.getFloat32(vertex3Begin + 8, true)
        };

        polygons.push({
            normal : normal,
            vertices : [vertex1, vertex2, vertex3]
        });
    }

    console.log(polygons);
    app.ports.polygon.send(polygons);
};

console.log("stl-loader!!");
xhr.send();

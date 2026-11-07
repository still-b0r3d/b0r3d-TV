' Pixel art. Rukus, loafing (the same sprite as b0r3d 95's buddy). In the rows a dot is
' clear; the letters are looked up in RukusColors().

function RukusLoaf() as object
    return [
        "..k...k.........",
        "..kk.kk.........",
        ".k12121kkkkkk...",
        ".k2k1k2k212121k.",
        ".k11s11k1212121k",
        ".kkOTkkk1111111k",
        ".kVUVVUV1111111k",
        ".k111111111222kk",
        "..kkkkkkkkkkkkk."
    ]
end function

' Fur 1, stripes 2, eyes 3, nose s, outline k; the marks O, T and V are fur, U is stripe.
function RukusColors() as object
    fur = &h9A9AA2FF
    stripe = &h5C5C66FF
    colors = {}
    colors.AddReplace("k", &h14121CFF)
    colors.AddReplace("1", fur)
    colors.AddReplace("O", fur)
    colors.AddReplace("T", fur)
    colors.AddReplace("V", fur)
    colors.AddReplace("2", stripe)
    colors.AddReplace("U", stripe)
    colors.AddReplace("3", &hC8E060FF)
    colors.AddReplace("s", &hE8B890FF)
    return colors
end function

sub DrawSprite(s as object, rows as object, colors as object, x as integer, y as integer, scale as integer)
    for r = 0 to rows.Count() - 1
        pattern = rows[r]
        for c = 0 to pattern.Len() - 1
            px = pattern.Mid(c, 1)
            if colors.DoesExist(px) then s.DrawRect(x + c * scale, y + r * scale, scale, scale, colors[px])
        end for
    end for
end sub


@rem combine images generated with image_label.pl

cd c:\Users\bruce\Documents\inaturalist\poster_plants

magick montage * -tile 9x17 -geometry 532x375+2+2 ../poster_plant.png    

@rem   magick montage * -tile  8x17  -geometry 596x425+2+2 ../poster_plant1.png   4800 x 7300  136 photos   36x24
@rem   magick montage * -tile  8x18  -geometry 596x425+2+2 ../poster_plant1.png   4800 x 7722  144 photos
@rem   magick montage * -tile  9x16  -geometry 530x375+2+2 ../poster_plant1.png   4806 x 6064  144 photos 
@rem   magick montage * -tile  9x17  -geometry 530x375+2+2 ../poster_plant1.png   4806 x 6439  153 photos   40x30
@rem   magick montage * -tile  9x19  -geometry 530x375+2+2 ../poster_plant1.png   4806 x 7189  171 photos 

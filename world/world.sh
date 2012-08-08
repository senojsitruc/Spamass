for v in {0..15}; do for h in {0..15}; do wget -o wget.out -O "4-$v-$h.jpg" "http://services.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/4/$v/$h"; done; done

# http://www.arcgis.com/home/webmap/viewer.html?services=f2498e3d0ff642bfb4b155828351ef0e


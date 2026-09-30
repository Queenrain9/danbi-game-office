extends RefCounted
static func all()->Array:
 var a=[]
 a.append({"title":"Opening Night","duration":60.0,"cues":[[6.0,"light_a",75],[13.0,"curtain",100],[20.0,"prop","ROSE"],[29.0,"light_b",50],[39.0,"curtain",25],[51.0,"prop","LETTER"]],"incidents":[[24.0,"snag"],[45.0,"drop"]]})
 a.append({"title":"Moonlit Letter","duration":60.0,"cues":[[5.0,"light_b",75],[11.0,"prop","LETTER"],[18.0,"light_a",25],[27.0,"curtain",50],[36.0,"prop","LAMP"],[44.0,"light_b",25],[53.0,"curtain",100]],"incidents":[[22.0,"drop"],[41.0,"snag"]]})
 a.append({"title":"Final Bow","duration":60.0,"cues":[[4.0,"curtain",25],[9.0,"light_a",100],[15.0,"prop","LAMP"],[22.0,"light_b",75],[29.0,"prop","ROSE"],[35.0,"curtain",75],[43.0,"light_a",50],[50.0,"prop","LETTER"],[56.0,"curtain",100]],"incidents":[[17.0,"snag"],[38.0,"drop"],[52.0,"snag"]]})
 return a

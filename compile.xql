(:
 :  eXide - web-based XQuery IDE
 :  
 :  Copyright (C) 2014 Wolfgang Meier
 :
 :  This program is free software: you can redistribute it and/or modify
 :  it under the terms of the GNU General Public License as published by
 :  the Free Software Foundation, either version 3 of the License, or
 :  (at your option) any later version.
 :
 :  This program is distributed in the hope that it will be useful,
 :  but WITHOUT ANY WARRANTY; without even the implied warranty of
 :  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 :  GNU General Public License for more details.
 :
 :  You should have received a copy of the GNU General Public License
 :  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 :)
xquery version "1.0";

declare option exist:serialize "method=json media-type=text/javascript";

let $data := request:get-data()
let $baseURI := request:get-header("X-BasePath")
let $query :=
    if($data instance of xs:base64Binary) then
        util:binary-to-string($data)
    else
        $data
return
  util:compile-query($query, $baseURI)
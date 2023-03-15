#Bend redius and node stress 
"""
db is diameter of the bar
bs is width of strut
wt is tie width
fy is yield strength of the bar
fc′ is concrete compressive strength

Notes:
    1. Since the clear cover is more likely to be more than  2db,
        I will assume every bar satisfies this condition. 
    2. This part is 

each node: 
find the maximum Ats, and minimum bs to calculate the most conservative value of rb
(minimum value of rb)
*** Ats is the total bar area, in the case of many layers of bars. 
The value rb will be specified to a node as a whole, not a given path
"""
if score == 2 
    rb = 2*Ats*fy/(bs*fc′)
else if score == 1
    rb = 1.5*Ats*fy/(wt*fc′)



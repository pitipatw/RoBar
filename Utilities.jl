
# function [point_map , A] = coarse(nnx, nny,L,H)
begin
using LinearAlgebra
"""
Todo
Group "count" into a single loop.
"""
function groundStruct(nnx::Int64, nny::Int64, L::Float64, H::Float64)
    # size of each element along x and y axis 
    lx::Float64 = L/(nnx-1) 
    ly::Float64 = H/(nny-1) 
    # total number of the elements
    total = nnx*nny ; 
    # point_map is a matrix that contains coordinates of the points
    point_map = zeros(total,4) ; 
    for i = 1:total 
        xpt = mod(i,nnx) ;
        if xpt == 0 
            xpt = nnx ; #last point in the row
        end 
        ypt = (i-xpt)/nnx+1;
    
        point_map[i,1] = xpt ;
        point_map[i,2] = ypt ;
        #these 2 lines could be done later. Matrix operation faster?
        point_map[i,3] = (xpt-1)*lx ;
        point_map[i,4] = (ypt-1)*ly ; 
    end
    #add point lable
    # println("Point Map Original")
    # display(point_map)
    
    point_map = hcat((1:nnx*nny) , point_map) ;
    # println("Point Map Modified")
    #display(point_map)

    # Create Grid line 
    # find total number of lines "in grid"
    # nnx*(nny-1)+nny*(nnx-1) + 
    g1 = zeros(nnx*(nny-1)+nny*(nnx-1) , 2) ;
    count = 0 ; 
    for j =1:(nny-1)
        for i = 1:(nnx-1) 
            count = count +1 ;
            pt = (j-1)*nnx+i ;
            g1[count,1] = pt ;
            g1[count,2] = pt+1 ;
            count = count+1 ;
            g1[count,1] = pt ;
            g1[count,2] = pt+nnx ;
        end
    end
    # vertical lines
    for i = 1:nny-1
        count =count +1;
        pt = nnx*i;
        g1[count,1] = pt ;
        g1[count,2] = pt+nnx ;
    end
    # horizontal lines
    for j = 1:nnx-1
        count = count +1 ;
        pt = nnx*(nny-1)+j ; 
        g1[count,1] = pt ;
        g1[count,2] = pt+1 ;
    end
    
    # find diagonal line 
    count = 1 ; 
    d = zeros((nnx-1)*(nny-1)*2,2) ; 
    for j = 1:(nny-1)
        for i = 1:(nnx-1)
            pt = (j-1)*nnx+i ; 
            d[count:count+1,1:2] = diagonal_line(pt,pt+1,pt+nnx,pt+nnx+1) ;
            count = count+2 ;
        end
    end
    
    
    A = [g1;d];
    return [A ,point_map]
end

"""
point in the form of 
    x3    x4
        
    x1    x2
"""
function diagonal_line(x1::Int64,x2::Int64,x3::Int64,x4::Int64)
    A = [x1 x4 ;x2 x3] 
    return A
end

"""
Get length of each element.
"""
function get_length(ien::Any,xn::Any)
    k = size(ien,2) ;
    sL = zeros(1,k)  ;
    for i = 1:k
        n = ien[:,i] ;
        x1 = xn[:,trunc(Int,n[1])] ; 
        x2 = xn[:,trunc(Int,n[2])] ; 
        v = x2-x1 ;
        L = norm(v,2) ;
        sL[1,i] = L ; 
    
    end
    return sL
end

end

# """
# #  ==== Do not run after this line.
# elements, point_map = groundStruct(3,4,9.,18.)
# # plotground(point_map, elements)
# # using CairoMakie

# f = Figure()
# ax = Axis(f[1, 1])
# f
# outx = []
# outy = []
# for i = axes(elements,1)
#     # println(i)
#     pt1::Int64= elements[i,1]
#     pt2::Int64= elements[i,2] 
#     println([pt1 pt2])
#     x1 = point_map[pt1,4]
#     y1 = point_map[pt1,5]
#     x2 = point_map[pt2,4]
#     y2 = point_map[pt2,5]
#     outx = vcat(outx,x1)
#     outx = vcat(outx,x2)
#     outy = vcat(outy,y1)
#     outy = vcat(outy,y2)
    
# end

# plot(outx,outy)
# return current()
# """
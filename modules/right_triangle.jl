println("right_triangle.jl -- by Lukas Stuelke.")
using Distributed
Distributed.@everywhere begin
	function find_diameter() # Finds the diameter of a regular polygon using symmetries.
		return 2^(1/2)
	end

	function param(a)
		m = 2+2^(1/2)
		a = a%1
		if a <= 0 || a >= 1
			toReturn = (0, 0)
		elseif a <= 1/m
			toReturn = (m*a, 0)
		elseif a <= (m-1)/m
			toReturn = (-(m-1)*(a+1/m-1), (m-1)*(a-1/m))
		else
			toReturn = (0, m*(1-a))
		end
		return toReturn
	end

	function dist(x) # Finds the euclidean distance of two points on the unit interval after paramaterization above.
		return sqrt((param(x[1])[1]-param(x[2])[1])^2+(param(x[1])[2]-param(x[2])[2])^2)
	end
end

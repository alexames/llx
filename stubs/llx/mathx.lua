---@meta

---@class llx.mathx
local mathx = {}

---@param x number
---@param lo number
---@param hi number
---@return number
function mathx.clamp(x, lo, hi) end

---@param x number
---@param precision? integer
---@return number
function mathx.round(x, precision) end

---@param x number
---@return integer
function mathx.sign(x) end

---@param a number
---@param b number
---@param t number
---@return number
function mathx.lerp(a, b, t) end

---@param a number
---@param b number
---@param v number
---@return number
function mathx.inverse_lerp(a, b, v) end

---@param v number
---@param in_lo number
---@param in_hi number
---@param out_lo number
---@param out_hi number
---@return number
function mathx.remap(v, in_lo, in_hi, out_lo, out_hi) end

---@param sequence number[]
---@return number
function mathx.mean(sequence) end

---@param sequence number[]
---@return number
function mathx.median(sequence) end

---@param sequence any[]
---@return any
function mathx.mode(sequence) end

---@param sequence number[]
---@return number
function mathx.variance(sequence) end

---@param sequence number[]
---@return number
function mathx.pvariance(sequence) end

---@param sequence number[]
---@return number
function mathx.stdev(sequence) end

---@param sequence number[]
---@return number
function mathx.pstdev(sequence) end

---@param sequence number[]
---@return number
function mathx.harmonic_mean(sequence) end

---@param sequence number[]
---@return number
function mathx.geometric_mean(sequence) end

---@param sequence number[]
---@param q number
---@return number
function mathx.quantile(sequence, q) end

---@param a integer
---@param b integer
---@return integer
function mathx.gcd(a, b) end

---@param a integer
---@param b integer
---@return integer
function mathx.lcm(a, b) end

---@param n integer
---@return integer
function mathx.factorial(n) end

---@param a integer
---@param b integer
---@return integer, integer
function mathx.divmod(a, b) end

---@param x number
---@param lo number
---@param hi number
---@return boolean
function mathx.in_range(x, lo, hi) end

---@param x number
---@param lo number
---@param hi number
---@return number
function mathx.wrap_around(x, lo, hi) end

---@param x number
---@return boolean
function mathx.is_nan(x) end

---@param x number
---@return boolean
function mathx.is_inf(x) end

return mathx

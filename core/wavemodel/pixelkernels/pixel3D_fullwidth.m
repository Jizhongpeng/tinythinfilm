function  kernel = pixel3D_fullwidth(width_x,width_y)
%  PIXEL_FULLWIDTH  Returns the kernel for a pixel size equal to filter size as an anonymous function which can be evaluated at any spatial frequency.
%
%  Inputs:    
%   - width: width of the pixel (use units consistent with other distances)
%  
%  Outputs:
%    kernel: anonymous function which can be evaluated as kernel(nu)
%    
%  Notes:
%  The pixel kernel is not intended for independent usage. It is used to make TINYTRANSMITTANCE correctly integrate the incidence flux on the pixel area.
%
%  From an implementation perspectrive, this convolution approach reduces memory requirements and facilitates speed ups.
%    
% Copyright Thomas Goossens    
    sinca=@(x)sinc(x/pi);
    kernel = @(nu) width*sinca(pi*width*nu);     
end
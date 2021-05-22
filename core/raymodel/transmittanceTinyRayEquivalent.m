function [T] = transmittanceTinyRayEquivalent(n0,neff,nsub,R,filterwidth,cwl,wavelengths,angledeg,polarization,varargin)
% transmittanceTinyRayEquivalent
% Simulate tiny transmittance of a Fabry-Pérot using a ray based model
%
% [T] = transmittanceTinyRayEquivalent(n0,neff,nsub,R,width,cwl,wavelengths,angledeg,polarization,accuracy)
%
%   Inputs
%    - n0: Refractive index incident medium
%    - neff: effective refractive index of the cavity
%    - nsubstrate:Refractive index substrate
%    - R: Product of reflection coefficients
%    - width: Width of the film
%    - cwl: Central wavelength of the filter (same units as width)
%    - wavelengths (Wx1): Wavelengths (same units as height)
%    - angledeg:  Incidence angle in degrees
%    - polarization ('s' or 'p')
%
%  Variable inputs
%    - 'accuracy': Subdivide integration domain in 2^floor(accuracy) points
%    - 'fastapproximation': Calculate the transmittance using an
%                              analytical approxmiation that evaluates faster. By default false.
%                              This approximation is very good for narrowband filters
%     - 'pixel' a pixel (see pixel2D) to change size of pixel relative to
%               filter size. By default the pixel will have the same size
%               as the filter. The pixel can not be outside of the filter
%   Outputs
%    - T (Wx1):  Ray-model estimation of the transmittance of a tiny Fabry-Pérot filter
%
%  Copyright Thomas Goossens
%  http://github.com/tgoossens/tinythinfilm
%


%% Polarization recursion
% If upolarized, recursively do the separate polarizations and average out
% the transmittancesx
if(or(polarization=='unpolarized',polarization=='unpolarised'))
    [T_s] = transmittanceTinyRayEquivalent(n0,neff,nsub,R,filterwidth,cwl,wavelengths,angledeg,'s',varargin{:}) ;
    [T_p] = transmittanceTinyRayEquivalent(n0,neff,nsub,R,filterwidth,cwl,wavelengths,angledeg,'p',varargin{:}) ;
    T =  0.5*(T_s+T_p);
    return;
end

%% Variable argument saccuracy,flag_fastapproximation
variableinputs = ieParamFormat(varargin);
p = inputParser;
p.addParameter('accuracy', 6, @isnumeric);
%p.addParameter('polarization', 'unpolarized');
p.addParameter('fastapproximation',true,@islogical);
p.addParameter('pixel',pixel2D('width',filterwidth));

p.parse(variableinputs{:});


accuracy= p.Results.accuracy;
flag_fastapproximation= p.Results.fastapproximation;
pixel= p.Results.pixel;
%polarization=p.Results.polarization;








%% Full thin film stack
equivstack = [1 neff nsub];

% Cosineof refraction angle
costh_n = sqrt(1-sind(angledeg).^2./equivstack.^2);

% Calculate characteristic admittances depending on polarization
if(polarization=='s')
    eta0=n0*costh_n(1);
    eta1=neff*costh_n(2);
    eta2=nsub*costh_n(3);
elseif(polarization=='p')
    eta0=n0/costh_n(1);
    eta1=neff/costh_n(2);
    eta2=nsub/costh_n(3);
end

% Transmission coefficient between incident medium and substrate (in absence of
% monolayer)
tsub =  2*eta0./(eta0+eta2);


% Filter dimensions
height=cwl/(2*neff);
w=filterwidth;

% Pixel range
% The left of the filter by convention is at x=0; We need to do a coodinate
% transform. X=-filterwidth/2 becomes the origin
pixelwidth = pixel.range.x(2)-pixel.range.x(1);
pixel_start=pixel.range.x(1)-(-filterwidth/2);
pixel_end=pixel_start+pixelwidth;


% Sampling of spatial pixel axis
x=linspace(pixel_start,pixel_end,2^floor(accuracy));
dx = abs(x(2)-x(1));

% Calculation of number of reflections (anonymous fucntion)
th_n = @(th) asind(sind(th)/neff);
num=@(x,th)x./(height*tand(th_n(th)));
N = @(x,th) floor(num(x,th)/2+1/2);

T = zeros(numel(wavelengths),1);

% Phase thickness

delta =(2*pi*equivstack(2)*height*costh_n(2)./wavelengths') ; %


% Analytical approximation
if(flag_fastapproximation)
    % Because of continuum approximation, we need to subtract pi, see supplementary material of Paper XX)
    delta_ct =delta- pi;
    
    % Maximum number of interfering rays, Bounded to avoid numerical
    % problems when M=infinity at normal incidence
    M1 = floor(min(pixel_start*neff/(cwl*tand(angledeg/neff)),1e7));
    M2 = floor(min(pixel_end*neff/(cwl*tand(angledeg/neff)),1e7));
    
    % Analytical equation
%    Tm= @(M) (real(eta2)/real(eta0))*(conj(tsub)*tsub).*(1-R).^2 .* (1+ (R.^(2*M)-1)./log(R.^(2*M))-2*(log(R).*(R.^M .*cos(2*M*delta_ct)-1)+2*delta_ct.*R.^M.*sin(2*M.*delta_ct))./(4*M.*delta_ct.^2+M.*log(R).^2))./(1-2*R*cos(2*delta_ct)+R.^2);
    
    part2=-(R.^(2*M1)-R.^(2*M2))./(2*log(R).*(M2-M1));
    part3= (2*R.^(M1) .*(2*delta_ct.*sin(2*M1*delta)+cos(2*M1*delta_ct).*log(R)))./((M2-M1).*(4*delta_ct.^2+log(R).^2));
    part4= -(2*R.^(M2) .*(2*delta_ct.*sin(2*M2*delta_ct)+cos(2*M2*delta_ct).*log(R)))./((M2-M1).*(4*delta_ct.^2+log(R).^2));
    T=(real(eta2)/real(eta0))*(conj(tsub)*tsub).*(1-R).^2 .*(1+part2+part3+part4) ./(1-2*R*cos(2*delta_ct)+R.^2);;
    
else
    % Numerical summation of the different contributions (with different
    % number of interfering rays
    for ix=1:numel(x)
        n = min(N(x(ix),angledeg),1e7);  % Number of interfering rays is limited to avoid division by zero when n=Inf
        formula=(R^(2*n)-2*R^(n)*cos(2*n*delta)+1)./(R^(2)-2*R*cos(2*delta)+1);
        T = T+dx*formula;
    end
    T = (real(eta2)/real(eta0))*(conj(tsub)*tsub)*(1-R)^2*T/filterwidth;
end






end

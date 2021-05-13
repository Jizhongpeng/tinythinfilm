
function wavepacket =  wavepacket3DLensVignetted(coneangle_deg,cra_deg,azimuth_deg,vignetting_radius,vignetting_sensitivity,exitpupil_distance) 
% wavepacket3DLens
%  Wavepacket (angular spectrum) of light focused from a circular aperture (lens) onto a square filter of
%  width 'filterwidth'.
%
%  wavepacket =   wavepacket3DLens(coneangle_deg,cra_deg,azimuth_deg,filterwidth)
%     
%   Inputs
%     coneangle_deg - Half-cone angle of the focused light beam (related to
%                     f-number) in degrees
%     cra_deg - Chief ray angle in degrees
%     azimuth_deg - Off-axis direction
%
%   Outputs
%     wavepacket - An anonymous function @(filterwidth,nu_x,nu_y,wavelength) which
%                  represents the angular spectrum at specified wavelengths
%
%  Copyright Thomas Goossens  
%  http://github.com/tgoossens/tinythinfilm
%    
    wavepacket = @field;
    function wavepacket_in = field(filterwidth,nu_x,nu_y,wavelength)   
        
        if(numel(filterwidth)==2)
            filterwidth_x=filterwidth(1);
            filterwidth_y=filterwidth(2);
        else
            filterwidth_x=filterwidth;
            filterwidth_y=filterwidth_x;
        end
        
        
        circ = @(u,radius) double(abs(u)<=radius);

        zi=1; % it doesn't matter for the pupil function (it is normalized out)
        % however for comparison with the equations in article i keep it in
        zi= exitpupil_distance;
        
        
        di=zi*tand(cra_deg);
        lensradius=zi*tand(coneangle_deg);
        
        P0vignet = @(x,y) circ(sqrt(x.^2+y.^2),vignetting_radius);
        
        offset_vignettingcircle = -vignetting_sensitivity*tand(cra_deg); % dv
        Pvignet = @(x,y)P0vignet(x+offset_vignettingcircle*cosd(azimuth_deg),y+offset_vignettingcircle*sind(azimuth_deg));
        
        % The pupil function of the lens is the product of the two pupils,
        % this is equivalent to an INTERSECTION or logical AND operatio.
        P0 = @(x,y) circ(sqrt(x.^2+y.^2),lensradius);
        P0lens = @(x,y) P0(x,y) .*Pvignet(x,y);
        
        P = @(x,y) P0lens(x+di*cosd(azimuth_deg),y+di*sind(azimuth_deg));
%         
%         figure;hold on
%         subplot(121)
%         spy(P0(-wavelength.*zi.*nu_x,-wavelength.*zi.*nu_y),'r');
%         spy(Pvignet(-wavelength.*zi.*nu_x,-wavelength.*zi.*nu_y),'b');
%         subplot(122)
%         spy(P0lens(-wavelength.*zi.*nu_x,-wavelength.*zi.*nu_y),'r');
%         
        filteraperture = filterwidth_x.*filterwidth_y.*sinca(pi*filterwidth_x*nu_x).*sinca(pi*filterwidth_y*nu_y);
        pupilfunction= (P(-wavelength.*zi.*nu_x,-wavelength.*zi.*nu_y));
        
        numzero = sum(~(pupilfunction(:)==0));
        if(numzero==0)
            wavepacket_in =  pupilfunction;
            return
        end
        wavepacket_in = conv2fft(pupilfunction,filteraperture,'same');
    end

    function f = sinca(x)
        % Modified sinc function because matlab sinc function already includes the factor pi.
        % This makes notation consistent with definitions in the publications.
        f=sinc(x/pi);
    end
    
end
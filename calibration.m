% We assume that steps 1-3 are finsihed and done manually

% Create result file:

dir= datestr(datetime('now'));
mkdir(dir);
htmlfilename=sprintf('%s/calibrationresult.html',dir);
theHtmlfile = fopen(htmlfilename, 'w+');
fprintf(theHtmlfile, '<!DOCTYPE html>\n');
fprintf(theHtmlfile, '<html>\n');
fprintf(theHtmlfile, '<body>\n');
max_force = [];
%Turn of warnings
warning off;

mindatapoints = 6;

%Read the measured data:
M = csvread('spring_measure.csv');
%M = csvread('non_lin_spring.csv');

% Load the spring calibration frame:
open_system('spring_calibration');
force_original = M(:,1);
measured_position_original = M(:,2);

% Find linear regions:
for window=(mindatapoints):size(force_original)
    for l=1:(size(force_original)-window)
        % Do a linear regression on the data:
        force = force_original(l:l+window);
        measured_position = measured_position_original(l:l+window);
        lin = measured_position\force;
        %lin = force(2)/measured_position(2);

        % Decide on K-value
        k = lin;
        X = [ones(length(measured_position),1) measured_position];
        b = X\force;
        k = b(2);
        ic = b(1)*-1;
        % Cnfigure the solver:
        set_param('spring_calibration', 'StopTime', '3')

        % now do a simualtion  
        sv = [];
        for i = 1:size(force)
            m = force(i);
            SimOut = sim('spring_calibration');
            sv = [sv max(position.Data)];
        end
        
        %calculate an error
        % Here it is linear so r^2 is a good value.
        % In case of non-linear, we could generate
        % plots with values, and let user decide?

        error2 = [];
        ymean = mean(measured_position);
        yvmean2 = [];
        for i = 1:size(force)
            theError = sv(i) - measured_position(i);
            theError2 = theError^2;
            error2 = [error2 theError2];
            ydistm = measured_position(i) - ymean;
            ydistm2 = ydistm^2;
            yvmean2 = [yvmean2 ydistm2];
        end
        sume2 = sum(error2);
        sumym2 = sum(yvmean2);
        r2 = 1-(sume2/sumym2);

        %Output this results:
        fprintf(theHtmlfile,'<h1>Results for linear regression #dp:%d - window:%d</h1>\n',int32(l), int32(window));
        fprintf(theHtmlfile,'<br>r^2 = %d\n',r2);
        fprintf(theHtmlfile,'<br>k = %d\n', k);
        fprintf(theHtmlfile,'<br>ic = %d\n',ic);
        fprintf(theHtmlfile,'<br>&#937;_in_force=[%d, %d]\n', min(force), max(force));
        fprintf(theHtmlfile,'<br>&#937;_out_displacement = [%d, %d]\n', min(sv), max(sv));
        filename = sprintf('%s/plot_window_%d-%d.png',dir,int32(window),int32(l));
        plot(force,measured_position,'r',force,sv, 'b');
        fprintf(theHtmlfile, '<br><img src="../%s">\n', filename);
        fprintf(theHtmlfile,'<br>------------------------------\n');
        print(filename, '-dpng');
        
        % Create an m-file as addendum to store the static values. The
        % experimental frame consists of both the m file for parameters and
        % the slx file.
        mfilename=sprintf('%s/spring_frame_%d-%d.m',dir,max(force),min(force));
        mfile = fopen(mfilename, 'w+');
        fprintf('\%r^2 of k to calibrated data was: %d\n',r2);  
        fprintf(mfile,'k = %s;\n', k);
        fprintf(mfile,'max_force = [%d];\n', max(force));
        fprintf(mfile,'min_force= [%d];\n', min(force));
        fprintf(mfile,'ic = %s;\n', ic);
        fclose(mfile);
    end
end

fprintf(theHtmlfile,'</body> \n</html>\n\');
fclose(theHtmlfile);
% 
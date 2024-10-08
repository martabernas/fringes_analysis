classdef fringesAnalysisApp_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        Switch                         matlab.ui.control.Switch
        MinPeakProminenceSpinner       matlab.ui.control.Spinner
        MinPeakProminenceSpinnerLabel  matlab.ui.control.Label
        SetButton                      matlab.ui.control.Button
        ActualfileLabel                matlab.ui.control.Label
        FileNameLabel                  matlab.ui.control.Label
        NextfileButton                 matlab.ui.control.Button
        Label_3                        matlab.ui.control.Label
        SavefringeslocationsButton     matlab.ui.control.Button
        Label_2                        matlab.ui.control.Label
        Label                          matlab.ui.control.Label
        SelectpointsButton             matlab.ui.control.Button
        DeletepointsButton             matlab.ui.control.Button
        AddpointsButton                matlab.ui.control.Button
        SelectfilesButton              matlab.ui.control.Button
        UIAxes                         matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        spectrum = []; % matrix with wavelength and intensity
        path = '';
        file = '';
        lambdaPeak = [];
        intensityPeak = [];
        x = [];
        filesStruct = {};
        i = 1;
        numberOfFiles = 0;
        peakprominence = 0.7;
    end
    
    methods (Access = private)
        
        function drawSpectrum(app)
            plot(app.UIAxes, app.spectrum(:, 1), app.spectrum(:, 2)); hold(app.UIAxes, 'on');
            plot(app.UIAxes, app.lambdaPeak, app.intensityPeak, 'o'); hold(app.UIAxes, 'off');      
        end
        
        
        
        function readData(app)
            app.spectrum = table2array(readtable([app.path, app.file]));
            j = 1;
            while j <= size(app.spectrum, 1) % remove headerlines; NaN
            if ~isnan(app.spectrum(j, 1))
                break
            end
                j = j + 1;
            end
            
             app.spectrum = app.spectrum(j:end, :);
            app.findMinMax();
        end

        
        function findMinMax(app)
            [~, fringes_idx] = findpeaks(-app.spectrum(:, 2), 'MinPeakProminence',app.peakprominence); 
            lambdaMin = app.spectrum(fringes_idx, 1);
            intensityMin = app.spectrum(fringes_idx, 2);
            
            if isequal(app.Switch.Value, 'min&max')
                [~, fringes_idx] = findpeaks(app.spectrum(:, 2), 'MinPeakProminence',app.peakprominence); 
                lambdaMax = app.spectrum(fringes_idx, 1);
                intensityMax = app.spectrum(fringes_idx, 2);
            else
                lambdaMax = [];
                intensityMax = [];
            end
            app.lambdaPeak = [lambdaMin; lambdaMax];
            app.intensityPeak = [intensityMin; intensityMax];
            [app.lambdaPeak, idx] = sort(app.lambdaPeak);
            app.intensityPeak = app.intensityPeak(idx);
        end
    end 
    

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: SelectfilesButton
        function SelectfilesButtonPushed(app, event)
            [app.filesStruct,app.path] = uigetfile({'*.csv';'*.txt'},'MultiSelect','on');
            if iscell(app.filesStruct) 
                app.file = app.filesStruct{1};
                app.numberOfFiles = size(app.filesStruct, 2);
            else
                app.file = app.filesStruct;
                app.numberOfFiles = 1;
            end
            
            app.FileNameLabel.Text = app.file;
            app.readData();
            app.drawSpectrum();
            
            
        end

        % Button pushed function: SelectpointsButton
        function SelectpointsButtonPushed(app, event)
            brush(app.UIFigure, 'on');

        end

        % Button pushed function: AddpointsButton
        function AddpointsButtonPushed(app, event)
            brushedData = logical(app.UIAxes.Children(2).BrushData);
            app.lambdaPeak = [app.lambdaPeak; app.spectrum(brushedData, 1)];
            app.intensityPeak = [app.intensityPeak; app.spectrum(brushedData, 2)];
            [app.lambdaPeak, idx] = sort(app.lambdaPeak);
            app.intensityPeak = app.intensityPeak(idx);
            app.drawSpectrum();

        end

        % Button pushed function: DeletepointsButton
        function DeletepointsButtonPushed(app, event)
            brushedData = logical(app.UIAxes.Children(1).BrushData);
            app.lambdaPeak(brushedData) = [];
            app.intensityPeak(brushedData) = [];
            app.drawSpectrum();
        end

        % Button pushed function: SavefringeslocationsButton
        function SavefringeslocationsButtonPushed(app, event)
            lambda = app.lambdaPeak;
            save([app.path, app.file(1:end-4), '_locs.txt'], 'lambda', '-ASCII');
        end

        % Button pushed function: NextfileButton
        function NextfileButtonPushed(app, event)
            app.i = app.i + 1;
            if app.i <= app.numberOfFiles
                app.file = app.filesStruct{app.i};
                app.FileNameLabel.Text = app.file;
                app.readData();
                app.drawSpectrum();
            end
            
            
        end

        % Button pushed function: SetButton
        function SetButtonPushed(app, event)
            app.peakprominence = app.MinPeakProminenceSpinner.Value;
            app.findMinMax();
            app.drawSpectrum();
            
        end

        % Value changed function: Switch
        function SwitchValueChanged(app, event)
            app.findMinMax();
            app.drawSpectrum();
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            xlabel(app.UIAxes, 'Wavelength (nm)')
            ylabel(app.UIAxes, 'Intensity (dB)')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.Position = [28 132 565 255];

            % Create SelectfilesButton
            app.SelectfilesButton = uibutton(app.UIFigure, 'push');
            app.SelectfilesButton.ButtonPushedFcn = createCallbackFcn(app, @SelectfilesButtonPushed, true);
            app.SelectfilesButton.Position = [19 444 91 22];
            app.SelectfilesButton.Text = 'Select file(s)';

            % Create AddpointsButton
            app.AddpointsButton = uibutton(app.UIFigure, 'push');
            app.AddpointsButton.ButtonPushedFcn = createCallbackFcn(app, @AddpointsButtonPushed, true);
            app.AddpointsButton.Position = [263 58 115 24];
            app.AddpointsButton.Text = 'Add points';

            % Create DeletepointsButton
            app.DeletepointsButton = uibutton(app.UIFigure, 'push');
            app.DeletepointsButton.ButtonPushedFcn = createCallbackFcn(app, @DeletepointsButtonPushed, true);
            app.DeletepointsButton.Position = [263 89 115 24];
            app.DeletepointsButton.Text = 'Delete points';

            % Create SelectpointsButton
            app.SelectpointsButton = uibutton(app.UIFigure, 'push');
            app.SelectpointsButton.ButtonPushedFcn = createCallbackFcn(app, @SelectpointsButtonPushed, true);
            app.SelectpointsButton.Position = [132 58 52 55];
            app.SelectpointsButton.Text = {'Select '; 'points'};

            % Create Label
            app.Label = uilabel(app.UIFigure);
            app.Label.Position = [109 74 14 22];
            app.Label.Text = '1.';

            % Create Label_2
            app.Label_2 = uilabel(app.UIFigure);
            app.Label_2.Position = [236 74 25 22];
            app.Label_2.Text = '2. ';

            % Create SavefringeslocationsButton
            app.SavefringeslocationsButton = uibutton(app.UIFigure, 'push');
            app.SavefringeslocationsButton.ButtonPushedFcn = createCallbackFcn(app, @SavefringeslocationsButtonPushed, true);
            app.SavefringeslocationsButton.Position = [466 58 88 55];
            app.SavefringeslocationsButton.Text = {'Save fringes'' '; 'locations'};

            % Create Label_3
            app.Label_3 = uilabel(app.UIFigure);
            app.Label_3.Position = [443 74 25 22];
            app.Label_3.Text = '3.';

            % Create NextfileButton
            app.NextfileButton = uibutton(app.UIFigure, 'push');
            app.NextfileButton.ButtonPushedFcn = createCallbackFcn(app, @NextfileButtonPushed, true);
            app.NextfileButton.Position = [518 444 91 22];
            app.NextfileButton.Text = 'Next file';

            % Create FileNameLabel
            app.FileNameLabel = uilabel(app.UIFigure);
            app.FileNameLabel.Position = [220 444 248 22];
            app.FileNameLabel.Text = '--';

            % Create ActualfileLabel
            app.ActualfileLabel = uilabel(app.UIFigure);
            app.ActualfileLabel.Position = [150 444 61 22];
            app.ActualfileLabel.Text = 'Actual file:';

            % Create SetButton
            app.SetButton = uibutton(app.UIFigure, 'push');
            app.SetButton.ButtonPushedFcn = createCallbackFcn(app, @SetButtonPushed, true);
            app.SetButton.Position = [378 391 40 22];
            app.SetButton.Text = 'Set';

            % Create MinPeakProminenceSpinnerLabel
            app.MinPeakProminenceSpinnerLabel = uilabel(app.UIFigure);
            app.MinPeakProminenceSpinnerLabel.HorizontalAlignment = 'right';
            app.MinPeakProminenceSpinnerLabel.Position = [226 386 70 27];
            app.MinPeakProminenceSpinnerLabel.Text = {'Min. Peak '; 'Prominence'};

            % Create MinPeakProminenceSpinner
            app.MinPeakProminenceSpinner = uispinner(app.UIFigure);
            app.MinPeakProminenceSpinner.Step = 0.1;
            app.MinPeakProminenceSpinner.Limits = [0 Inf];
            app.MinPeakProminenceSpinner.Position = [304 389 65 22];
            app.MinPeakProminenceSpinner.Value = 0.7;

            % Create Switch
            app.Switch = uiswitch(app.UIFigure, 'slider');
            app.Switch.Items = {'min', 'min&max'};
            app.Switch.ValueChangedFcn = createCallbackFcn(app, @SwitchValueChanged, true);
            app.Switch.Position = [494 392 45 20];
            app.Switch.Value = 'min';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = fringesAnalysisApp_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end
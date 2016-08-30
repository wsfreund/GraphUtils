classdef NewZoomAndPan < handle
%
% Package GraphUtils: Class NewZoomAndPanListener
%   Add new zoom and pan options by holding the hotkeys.
%
%  Possible hotkeys are:
%
%    - ' ' (spacebar): hold space bar to pan.
%    - 'z': zoom-in on selected region
%    - 'Z': zoom-out (FIXME: not yet implemented)
%    - 'o': Overview all data
%    - 'x': Only axis x pan
%    - 'y': Only axis y pan
%    - 'b': All axes pan
%    - 'v': Only vertical zoom
%    - 'h': Only horizontal zoom
%    - 'a': All axes zoom
%    - 'r or 'u': Reset to previous view
%    - '0': Reset all configuration (zoom and pan will be on both axes)
%    - 'd': Enter/leave datatip mode.
%
%    Even if probably you won't need doing this, in case you want
% extract the newZAP object from the figure handle, do:
%
% getappdata(figH,'newZAP');
%
%    Known bugs: 
%   1 - After pushing alt-tab and holding a key for a while,
% the newZAP may get unresponsive. If that happens, just push alt-tab
% twice again and the figure will respond as expected. 
% More details at:
%
% http://stackoverflow.com/questions/18651177/windowkeypress-a-k-a-windowkeypressevent-and-keypressfcn-doesnt-trigger-afte
%
%   2 - If you select an object that is on the figure that is not an
% axes with tab or by clicking on it, it will also cause NewZoomAndPan
% malfunction.
%
%  theObj = NewZoomAndPanListener(figH,opt)
%
%                         ------  Inputs  -------
%
% -> figH (figure handle): the figure handle
%
% -> opt (string) <'create'>: May be one of the following:
%   - create: create NewZoomAndPan object and store it at the figH.
%   - delete: delete NewZoomAndPan object stored at the figH.
%   - activate: activate NewZoomAndPan listeners at the figH.
%   - deactivate: deactivate NewZoomAndPan listeners at the figH.


% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 28 Sep 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com> 

% TODO: Add a rectangle in the middle of the figure showing the
% pressed action. This should be configurable and possible to use the
% 'silent' mode.

% TODO: Add boolean variable to determine if it will listen to hole
% figure or just when on the axes. Also add axes that will listen or
% not to movement.

% TODO: Add compatibility with log scale.

  properties(SetAccess = private)
    figH = []
    onlyHorPan = 0
    onlyVertPan = 0
    onlyHorZoom = 0
    onlyVertZoom = 0
    keyPressed = false

    %nojava = false;

    overAllLimits = {};
    oldAxisLimits = {};

    panListener = []
    zoomListener = []

    clickStartPos = []

    axesH = []

    lastAxes = []
    lastAxesLine = []
    lastAxesColumn = []

    pressListener
    releaseListener
    lastAxesListener

    hListenerX = event.proplistener.empty
    hListenerY = event.proplistener.empty

    processedPressCallback = false;

    zoomPatchH

    isValidClickIn = false;

    curLine
    curColumn

    lastLine
    lastColumn

    nLines
    nColumns
  end

  properties(SetObservable)
    curAxes = []
  end


  methods

    function self = NewZoomAndPan(inHandle,opt)

      %
      % Based on:
      %
      % http://www.mathworks.com/matlabcentral/fileexchange/28603-inputemu-keyboard-mouse-emulator-v1-0-1/content/inputemu.m
      %
      % http://www.mathworks.com/matlabcentral/fileexchange/34728-graphical-wrappers/content/wrappers/FigureWrapper.m
      %
      % http://undocumentedmatlab.com/blog/inactive-control-tooltips-event-chaining/
      %
      
      %if ~usejava('awt') || ~usejava('jvm')
      %  self.nojava = true;
      %  Output.WARNING(['NILM_CEPEL:GraphUtils:newZoomAndPanListener:'...
      %    'JavaUnavailable'],['Java is unavailable! NewZAP will not '...
      %    'use the workaround for alt-tab anymore. If NewZAP ',...
      %    'get unresponsive, push alt-tab.']);
      %end

      if nargin < 2
        opt = 'create';
      end

      switch opt
      case 'create'
        % --------------   Create the newZAP data ------------
        switch class(handle(inHandle))
        case {'figure','matlab.ui.Figure'}
          self.figH = inHandle;
          % TODO This could be tested to get figure position:
          self.axesH=getappdata(inHandle,'axesH');
        case {'axes','matlab.graphics.axis.Axes'}
          if isscalar(inHandle)
            self.figH = ancestor(inHandle,'figure');
            self.axesH = inHandle;
          else
            self.figH = ancestor(inHandle(1),'figure');
            self.axesH = inHandle;
          end
        case {'hg2utils.HGHandle','GObject'}
          self.figH = ancestor(inHandle(1),'figure');
          if isempty(self.figH)
            self.figH = inHandle(1);
            self.axesH=getappdata(inHandle,'axesH');
          else
            if isscalar(inHandle)
              self.figH = ancestor(inHandle,'figure');
              self.axesH = inHandle;
            else
              self.figH = ancestor(inHandle(1),'figure');
              self.axesH = inHandle;
            end
          end
        end

        self.axesH = double(self.axesH);

        self.lastAxesListener = addlistener(self,'curAxes','PostSet',...
          @self.updateLastAxes);
        
        if feature('UseHG2')
          self.pressListener=addlistener(self.figH,'WindowKeyPress',...
            @(a,b) self.keyPressNewZoomAndPan(a,b));
          self.releaseListener=addlistener(self.figH,'WindowKeyRelease',...
            @(a,b) self.keyReleaseNewZoomAndPan(a,b));
        else
          self.pressListener=addlistener(self.figH,'WindowKeyPressEvent',...
            @(a,b) self.keyPressNewZoomAndPan(a,b));
          self.releaseListener=addlistener(self.figH,'WindowKeyReleaseEvent',...
            @(a,b) self.keyReleaseNewZoomAndPan(a,b));
        end

        self.nLines = size(self.axesH,1);
        self.nColumns = size(self.axesH,2);

        self.oldAxisLimits = cell(self.nLines,self.nColumns);
        self.overAllLimits = self.oldAxisLimits;

        % Store some configuration at figure handle
        for thisLine=1:self.nLines
          for thisColumn=1:self.nColumns
            self.curLine = thisLine;
            self.curColumn = thisColumn;
            if self.axesH(thisLine,thisColumn)
              self.curAxes = self.axesH(thisLine,thisColumn);
              % FIXME This could easily be stored inside this class
              self.oldAxisLimits{thisLine,thisColumn} = axis(self.curAxes);
              self.overAllLimits{thisLine,thisColumn} = axis(self.curAxes);
            else
              self.curAxes = [];
              % FIXME This could easily be stored inside this class
              self.oldAxisLimits{thisLine,thisColumn} = [];
              self.overAllLimits{thisLine,thisColumn} = [];
            end
            %if feature('UseHG2')
            %  self.hListenerX(k) = addlistener(self.curAxes,'XTick',...
            %    'PostSet', @updateOverAllLimits);
            %  self.hListenerY(k) = addlistener(self.curAxes,'YTick',...
            %    'PostSet', @updateOverAllLimits);
            %else
            %  xTickH = findprop(handle(handles(k,m)),'XTick');
            %  yTickH = findprop(handle(handles(k,m)),'YTick');
            %  self.hListenerX(k) = handle.listener(self.curAxes,xTickH,...
            %    'PropertyPostSet', @updateOverAllLimits);
            %  self.hListenerY(k) = handle.listener(self.curAxes,yTickH,...
            %    'PropertyPostSet', @updateOverAllLimits);
            %end
          end
        end

        % Store newZAP object at the figure handle:
        zap = getappdata(self.figH,'newZAP');
        setappdata(self.figH,'newZAP',[zap self]);

      case 'delete'
        % --------------   Delete the newZAP data ------------
        self = getappdata(figH,'newZAP');
        if isempty(self)
          Output.INFO('Figure doesn''t have newZAP object.\n');
          return;
        end
        try
          if isvalid(self)
            if feature('UseHG2')
              GraphUtils.deleteHandle(self.pressListener)
              GraphUtils.deleteHandle(self.releaseListener)
            end
            GraphUtils.deleteHandle(self.panListener);
            GraphUtils.deleteHandle(self.zoomListener);
            GraphUtils.deleteHandle(self.lastAxesListener);
            GraphUtils.deleteHandle(self.hListenerX);
            GraphUtils.deleteHandle(self.hListenerY);
            delete(self);
          end
          rmappdata(figH,'newZAP');
        catch ext
          Output.WARNING(['NILM_CEPEL:GraphUtils:NewZoomAndPan:NewZoomAndPan:'...
            'CouldNotDelete'],'Could not delete. Reason: \n%s',ext.getReport);
        end
      case 'activate'
        % --------------  Activate newZAP listeners ------------
        self = getappdata(figH,'newZAP');
        if isempty(self)
          Output.WARNING('Figure doesn''t have newZAP object.\n');
          return;
        end
        try
          if isvalid(self)
            if feature('UseHG2')
              self.pressListener.Enabled = true;
              self.releaseListener.Enabled = true;
              self.lastAxesListener.Enabled = true;
            else
              self.pressListener.Enabled = 'on';
              self.releaseListener.Enabled = 'on';
              self.lastAxesListener.Enabled = 'on';
            end
          else
            Output.WARNING('Figure doesn''t have newZAP object.\n');
            rmappdata(self.figH,'newZAP');
          end
        catch ext
          Output.WARNING(['NILM_CEPEL:GraphUtils:NewZoomAndPan:NewZoomAndPan:'...
            'CouldNotActivate'],'Could not activate. Reason: \n%s',ext.getReport);
        end
      case 'deactivate'
        % --------------  Deactivate newZAP listeners ------------
        self = getappdata(figH,'newZAP');
        if isempty(self)
          Output.WARNING('Figure doesn''t have newZAP object.\n');
          return;
        end
        try
          if isvalid(self)
            if feature('UseHG2')
              self.pressListener.Enabled = false;
              self.releaseListener.Enabled = false;
              self.lastAxesListener.Enabled = false;
            else
              self.pressListener.Enabled = 'off';
              self.releaseListener.Enabled = 'off';
              self.lastAxesListener.Enabled = 'off';
            end
          else
            Output.WARNING('Figure doesn''t have newZAP object.\n');
            rmappdata(figH,'newZAP');
          end
        catch ext
          Output.WARNING(['NILM_CEPEL:GraphUtils:NewZoomAndPan:NewZoomAndPan:'...
            'CouldNotActivate'],'Could not activate. Reason: \n%s',ext.getReport);
        end
      otherwise
        Output.ERROR(['NILM_CEPEL:GraphUtils:NewZoomAndPan:NewZoomAndPan:'...
          'UnknownOption'],['Option %s is unknown. The following'...
          ' options are available: create, delete, activate,'...
          ' deactivate'],opt);
      end

      %function updateOverAllLimits(~,eventData)
      %  hAxes = eventData.AffectedObject;
      %  setappdata(hAxes,'self.overAllLimits',axis(hAxes));
      %end

    end

    function updateOverAll(self,varargin)
      switch numel(varargin)
      case 1
        if size(overAll,1) == numel(self.overAllLimits,1) && ...
            size(overAll,2) == numel(self.overAllLimits,2)
          if all(cellfun('prodofsize',overAll)==4)
            self.overAllLimits = overAll;
          else
            Output.ERROR('NILM_CEPEL:GraphUtils:NewZoomAndPan:WrongInputs',...
              'All overAllLimits must have 4 double axes limits');
          end
        end
      case 2
        if numel(varargin{1}) == 1 && ...
            numel(varargin{2}) == 4
          self.overAllLimits{varargin{1}} = varargin{2};
        else
          Output.ERROR('NILM_CEPEL:GraphUtils:NewZoomAndPan:WrongInputs',...
            'Wrong inputs.');
        end
      case 3
        if numel(varargin{1}) == 1 && ...
            numel(varargin{2}) == 1 && ...
            numel(varargin{3}) == 4
          self.overAllLimits{varargin{1},varargin{2}} = varargin{3};
        else
          Output.ERROR('NILM_CEPEL:GraphUtils:NewZoomAndPan:WrongInputs',...
            'Wrong inputs.');
        end
      end
    end
  end

  methods(Access = private)
    function keyPressNewZoomAndPan(self,~,keyInfo)
    %
    % Actions taken when key are pressed.
    %
    % -> figH (figure handle): the figure handle.
    % 
    % -> keyInfo (event handle): Event information from the pressed key.
    % It has the following properties:
    %
    %   - Character: the character the key represents.
    %   - Modifier: If holding a modifier as shift, alt, so on...
    %   - Key: key pressed with the modifier.
    %
      %selType = get(gco,'Type');

      %if ~isempty(gco) && ~any(strcmp(selType,{'axes','figure'}))
      %  axesAct = ancestor(gco,'axes');
      %  if ~isempty(axesAct) && ~any(ancestor(gco,'axes')==self.axesH)
      %    Output.VERBOSE(['Ignoring click on newZAP figure because'...
      %      ' selected object is not figure/axes type: %s.\n'],...
      %      class(selType));
      %    return;
      %  end
      %end


      self.processedPressCallback = false;
      self.isValidClickIn = false;

      if feature('UseHG2')
        mChar = keyInfo.Character;
      else
        mChar = keyInfo.Source.CurrentCharacter;
      end

      Output.VERBOSE('Pushed button %s\n',mChar);

      switch mChar
      case ' ' % Hold space to pan
        if ~self.keyPressed
          self.keyPressed = true;
          self.curAxes = 0;
          if isempty(self.axesH)
            error('NILM_CEPEL:GraphUtils:newZoomAndPanListener:noAxesOrder',...
              'Cannot get the axesH from the current figure as expected.');
          end
          [isOverAxes,axesLine,axesColumn] = GraphUtils...
            .isOverAxes(self.figH,self.axesH,1);
          if isOverAxes
            self.isValidClickIn = true;
            self.curLine = axesLine;
            self.curColumn = axesColumn;
            self.curAxes = self.axesH(axesLine,axesColumn);
            [axesPosition,oldLimits] = GraphUtils...
              .getAxesPosLimits(self.curAxes);
            self.clickStartPos = GraphUtils.getCurPointerLocation;
            self.oldAxisLimits{axesLine,axesColumn} = oldLimits;
            figPosition = GraphUtils.getFigLimits(self.figH);
            overAll = self.overAllLimits{axesLine,axesColumn};
            if feature('UseHG2')
              self.pressListener.Enabled = false;
            else
              self.pressListener.Enabled = 'off';
            end
            if feature('UseHG2')
              self.panListener = addlistener(self.figH,...
                'WindowMouseMotion',@(a,b) newPan);
            else
              wn=warning('off','MATLAB:class:EventWillBeRenamed');
              self.panListener = addlistener(self.figH,...
                'WindowButtonMotionEvent',@(a,b) newPan);
              warning(wn.state,wn.identifier);
            end
          end
        end
      case 'z' % Use z to zoom on axes
        if ~self.keyPressed
          if feature('UseHG2')
            self.pressListener.Enabled = false;
          else
            self.pressListener.Enabled = 'off';
          end
          self.keyPressed = true;
          self.curAxes = 0;
          if isempty(self.axesH)
            error('NILM_CEPEL:GraphUtils:newZoomAndPanListener:noAxesOrder',...
              'Cannot get the axesH from the current figure as expected.');
          end
          [isOverAxes,axesLine,axesColumn] = GraphUtils...
            .isOverAxes(self.figH,self.axesH,1);
          if isOverAxes
            self.isValidClickIn = true;
            self.curLine = axesLine;
            self.curColumn = axesColumn;
            self.curAxes = self.axesH(axesLine,axesColumn);
            self.clickStartPos = GraphUtils.getCurPointerLocation;
            cp = self.clickStartPos;
            [axesPosition,oldLimits] = GraphUtils...
              .getAxesPosLimits(self.curAxes);
            GraphUtils.deleteHandle(self.zoomPatchH);
            self.zoomPatchH = [];
            self.zoomPatchH=patch([cp(1) cp(1) cp(1)+eps cp(1)+eps],...
              [cp(2) cp(2)+eps cp(2)+eps cp(2)],[0 0 0 0],...
              'FaceColor','none','EdgeColor',[.2 .2 .2],'Tag',...
              'self.zoomingArea','Parent',self.curAxes,...
              'HandleVisibility','off','HitTest','off');
            set(get(get(self.zoomPatchH,'Annotation'),'LegendInformation'),...
                'IconDisplayStyle','off'); % Exclude handle from legend
            if feature('UseHG2')
              self.zoomPatchH.FaceAlpha = .3;
              self.zoomPatchH.FaceColor = [.7 .7 .7];
              self.zoomListener = addlistener(self.figH,...
                'WindowMouseMotion',@(~,~) newZoom);
            else
              wn=warning('off','MATLAB:class:EventWillBeRenamed');
              self.zoomListener = addlistener(self.figH,...
                'WindowButtonMotionEvent',@(~,~) newZoom);
              warning(wn.state,wn.identifier);
            end
          end
        end
      end
      
      self.processedPressCallback = true;

      function newPan
      %
      % newPan will change axes position 
      %

        if GraphUtils.isMultipleCallback
          return;
        end
        % Get current position:
        curPos = GraphUtils.getCurPointerLocation;

        % Do the zoom in:
        if ~self.onlyVertPan
          dx = curPos(1) - self.clickStartPos(1);
          xScaleFactor = (oldLimits(2)-oldLimits(1)) / ...
            ( axesPosition(3) * figPosition(3) );
          dxAxisUnits = dx * xScaleFactor;
          newAxisLimits = oldLimits(1:2) - dxAxisUnits;
          if newAxisLimits(1)<overAll(1)
            newAxisLimits(2)=overAll(1)+oldLimits(2)-oldLimits(1);
            newAxisLimits(1)=overAll(1);
          elseif newAxisLimits(2)>overAll(2)
            newAxisLimits(1)=overAll(2)-(oldLimits(2)-oldLimits(1));
            newAxisLimits(2)=overAll(2);
          end
          xlim(self.curAxes,newAxisLimits);
        end

        if ~self.onlyHorPan
          dy = curPos(2) - self.clickStartPos(2);
          yScaleFactor = (oldLimits(4)-oldLimits(3)) / ...
            ( axesPosition(4) * figPosition(4));
          dyAxisUnits = dy * yScaleFactor;
          newAxisLimits = oldLimits(3:4) - dyAxisUnits;
          if newAxisLimits(1)<overAll(3)
            newAxisLimits(2)=overAll(3)+oldLimits(4)-oldLimits(3);
            newAxisLimits(1)=overAll(3);
          elseif newAxisLimits(2)>overAll(4)
            newAxisLimits(1)=overAll(4)-(oldLimits(4)-oldLimits(3));
            newAxisLimits(2)=overAll(4);
          end
          ylim(self.curAxes,newAxisLimits);
        end
      end

      function newZoom
      %
      % newZoom will draw the rectangle to where the axes will be zoomed to
      %

        % Polling:
        delay = 0.01;
        for idx = 1:(1/delay)  % wait up to N secs before giving up
          if self.processedPressCallback  % set by the callback
            break;
          end
          pause(delay);  % a slight pause to let all the data gather
          % done in the buttonPress
        end

        % Get current position:
        curPos = GraphUtils.getCurPointerLocation;

        figPosition = GraphUtils.getFigLimits(self.figH);

        if ~self.onlyVertZoom
          dx = abs(curPos(1) - self.clickStartPos(1));
          xScaleFactor = (oldLimits(2)-oldLimits(1)) / ...
            ( axesPosition(3) * figPosition(3));
          dxAxisUnits = dx * xScaleFactor;
          leftPos = min([curPos(1) self.clickStartPos(1)]-figPosition(1)...
            -axesPosition(1)*figPosition(3))*xScaleFactor...
            +oldLimits(1);
          xp = [leftPos leftPos+dxAxisUnits];
        else
          xp=xlim(self.curAxes);
        end

        if ~self.onlyHorZoom
          dy = abs(curPos(2) - self.clickStartPos(2));
          yScaleFactor = (oldLimits(4)-oldLimits(3)) / ...
            ( axesPosition(4) * figPosition(4) );
          dyAxisUnits = dy * yScaleFactor;
          botPos = min([curPos(2) self.clickStartPos(2)]-figPosition(2)...
            -axesPosition(2)*figPosition(4))*yScaleFactor...
            +oldLimits(3);
          yp = [botPos botPos+dyAxisUnits];
        else
          yp = ylim(self.curAxes);
        end

        zoomAreaX = [xp(1) xp(1) xp(2) xp(2)];
        zoomAreaY = [yp(1) yp(2) yp(2) yp(1)];

        set(self.zoomPatchH,'xdata',zoomAreaX,'ydata',zoomAreaY);
      end
    end



    function keyReleaseNewZoomAndPan(self,~,keyInfo)
    %
    % Actions taken when key are released.
    % 
      
      %selType = get(gco,'Type');

      %if ~isempty(gco) && ~any(strcmp(selType,{'axes','figure'}))
      %  axesAct = ancestor(gco,'axes');
      %  if ~isempty(axesAct) && ~any(ancestor(gco,'axes')==self.axesH)
      %    Output.VERBOSE(['Ignoring click on newZAP figure because'...
      %      ' selected object is not figure/axes type: %s.\n'],...
      %      class(selType));
      %    return;
      %  end
      %end


      if feature('UseHG2')
        mChar = keyInfo.Character;
      else
        mChar = keyInfo.Source.CurrentCharacter;
      end

      Output.VERBOSE('Released button %s\n',mChar);

      switch mChar
      case ' '
        if feature('UseHG2')
          self.pressListener.Enabled = true;
        else
          self.pressListener.Enabled = 'on';
        end
        self.keyPressed = false;
        % ------------- Finish Pan --------------------
        % Stop listening to mouse movement:
        GraphUtils.deleteHandle(self.panListener);
        self.panListener=[];
      case 'z'
        if feature('UseHG2')
          self.pressListener.Enabled = true;
        else
          self.pressListener.Enabled = 'on';
        end
        % ------------- Finish Zoom -------------------
        % Stop listening to mouse movement (if listening at all):
        GraphUtils.deleteHandle(self.zoomListener);
        self.zoomListener = [];
        GraphUtils.deleteHandle(self.zoomPatchH);
        self.zoomPatchH = [];
        self.keyPressed = false;
        if ~self.isValidClickIn
          self.isValidClickIn = false;
          return
        end

        if ~isempty(self.curAxes) 
          GraphUtils.deleteHandle(self.zoomPatchH);
          self.zoomPatchH = [];

          [axesPosition,oldLimits] = GraphUtils...
            .getAxesPosLimits(self.curAxes,'normalized');
          curPos = GraphUtils.getCurPointerLocation;
          figPosition = GraphUtils.getFigLimits(self.figH,'normalized');
          % Do the zoom in:
          if ~self.onlyVertZoom
            % FIXME Check if zoom is inbound (create inbound function...)
            % TODO If no dx, half zoom screen at current point
            dx = abs(curPos(1) - self.clickStartPos(1));
            xScaleFactor = (oldLimits(2)-oldLimits(1)) / ...
              ( axesPosition(3) * figPosition(3));
            dxAxisUnits = dx * xScaleFactor;
            leftPos = min([curPos(1) self.clickStartPos(1)]-figPosition(1)...
              -axesPosition(1)*figPosition(3))*xScaleFactor...
              +oldLimits(1);
            if dxAxisUnits>20*eps
              xlim(self.curAxes,[leftPos leftPos+dxAxisUnits]);
            else
              Output.INFO(['Canceled x axis zooming: Window is too'...
                ' small.\n']);
            end
          end

          if ~self.onlyHorZoom
            dy = abs(curPos(2) - self.clickStartPos(2));
            yScaleFactor = (oldLimits(4)-oldLimits(3)) / ...
              ( axesPosition(4) * figPosition(4) );
            dyAxisUnits = dy * yScaleFactor;
            botPos = min([curPos(2) self.clickStartPos(2)]-figPosition(2)...
              -axesPosition(2)*figPosition(4))*yScaleFactor...
              +oldLimits(3);
            if dyAxisUnits>20*eps
              ylim(self.curAxes,[botPos botPos+dyAxisUnits]);
            else
              Output.INFO(['Canceled y axis zooming: Window is too'...
                ' small.\n']);
            end
          end
          % FIXME This throws an error sometimes.
          if (~self.onlyVertZoom && dxAxisUnits>20*eps) ...
            || (~self.onlyHorZoom && dyAxisUnits>20*eps) ...
            || dxAxisUnits>20*eps || dyAxisUnits>20*eps
            self.oldAxisLimits{self.curLine,self.curColumn} = ...
              oldLimits;
          end
        end
      case 'o' % Use o to overview all data
        axisLimits = cell(self.nLines,self.nColumns);
        for thisLine=1:self.nLines
          for thisColumn=1:self.nColumns
            localAxes = self.axesH(thisLine,thisColumn);
            if ~localAxes
              continue
            end
            axisLimits{thisLine,thisColumn} = axis(localAxes);
          end
        end
        for thisLine=1:self.nLines
          for thisColumn=1:self.nColumns
            localAxes = self.axesH(thisLine,thisColumn);
            if ~localAxes
              continue
            end
            overAll = self.overAllLimits{thisLine,thisColumn};
            Output.VERBOSE('OverAll limits for axes(%d,%d):[%d %d %d %d].\n',...
              thisLine,thisColumn,overAll(1),overAll(2),overAll(3),overAll(4));
            if ~isequal(axisLimits{thisLine,thisColumn},overAll)
              Output.VERBOSE(['Setting axes(%d,%d) to'...
                ' overAll.\n'],thisLine,thisColumn);
              self.oldAxisLimits{thisLine,thisColumn} = ...
                axisLimits{thisLine,thisColumn};
              axis(localAxes,overAll);
            end
          end
        end
      case 'd' % Enter/leave datatip mode
        datacursormode(self.figH,'toggle');
      case 'x' % Only axis x will pan
        self.onlyHorPan = 1;
        self.onlyVertPan = 0;
      case 'y' % Only axis y will pan
        self.onlyHorPan = 0;
        self.onlyVertPan = 1;
      case 'b' % All axes will pan
        self.onlyHorPan = 0;
        self.onlyVertPan = 0;
      case 'v' % Only vertical zoom
        self.onlyHorZoom = 0;
        self.onlyVertZoom = 1;
      case 'h' % Only horizontal zoom
        self.onlyHorZoom = 1;
        self.onlyVertZoom = 0;
      case 'a'
        self.onlyHorZoom = 0;
        self.onlyVertZoom = 0;
      case {'r','u'} % Reset to old view
        axisLimits = axis(self.lastAxes);
        oldLimits = self.oldAxisLimits{self.lastLine,...
          self.lastColumn};
        Output.DEBUG('Old limits for lastAxes(%d,%d):[%d %d %d %d].\n',...
          self.lastLine,self.lastColumn,oldLimits(1),oldLimits(2),...
          oldLimits(3),oldLimits(4));
        if ~isequal(axisLimits,oldLimits)
          Output.VERBOSE('Setting lastAxes to oldLimits.\n');
          self.oldAxisLimits{self.lastLine,self.lastColumn} = axisLimits;
          axis(self.lastAxes,oldLimits);
        end
      case 'Z' % zoom out
      case '0' % Reset all configuration (zoom and pan will be on both
        % axes)
        self.onlyHorPan = 0;
        self.onlyVertPan = 0;
        self.onlyHorZoom = 0;
        self.onlyVertZoom = 0;
      end

      self.isValidClickIn = false;

    end

    function updateLastAxes(self,varargin)
      if ~isempty(self.curAxes) && self.curAxes
        self.lastAxes = self.curAxes;
        self.lastLine = self.curLine;
        self.lastColumn = self.curColumn;
      end
    end

  end

end

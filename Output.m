classdef Output
%
% Class Output.
%   Class to determine output level of information.
%
% --- Usage Instructions ---
%
% At your files, use the methods: 
%
%     - Output.VERBOSE
%     - Output.DEBUG
%     - Output.INFO
%     - Output.WARNING
%     - Output.ERROR
%
% as you would do with sprintf. I.e:
%
%     Output.DEBUG(['Display Message with %d and'...
%       %s.'],integer_output,string_output);
%
%   For the information level messages (INFO, DEBUG, VERBOSE), the
% last argument may be '-appendNextMessage' so that the next message
% with the same depth of information will be appended to the last
% message, instead of entering the full labeled message again, i.e.:
%
%   Output.INFO('Message1.');
%   Output.INFO('Message2.');
%
% produces:
% 
%   INFO:    MATLAB.INTERPRETER             Message1.
%   INFO:    MATLAB.INTERPRETER             Message2.
%
% , whereas:
%
%   Output.INFO('Doing some procedure...','-appendNextMessage');
%   Output.INFO(' Done!');
%
% produces:
%
%   INFO:    MATLAB.INTERPRETER             Doing some procedure...  Done!
%
% but it will get ineffective if it is output a message from another
% level --- including WARNING or ERROR --- (or it happens due to
% another thread), that is:
%
%   Output.INFO('Doing some procedure...','-appendNextMessage');
%   Output.DEBUG('Message.');
%   Output.INFO('Done!');
%
% produces:
%
%   INFO:    MATLAB.INTERPRETER             Doing some procedure...  
%   DEBUG:   MATLAB.INTERPRETER             Message.
%   INFO:    MATLAB:INTERPRETER             Done!
%
%   Leaving that aside, the message will be displayed depending on the
% output level. The default output level is DISP_INFO, which will
% display INFO messages (used with Output.INFO function).  
%
%   Output.level(Output.DISP_DEBUG)
%
% Possible levels are:
%
%   - DISP_VERBOSE: All possible output.
%   - DISP_DEBUG: Debug mLvl.
%   - DISP_INFO: Info mLvl (default).
%   - DISP_WARNING: Only warnings.
%   - MUTE: Only fatal outputs will be displayed.
%
%
%   Also, if you want the output to go to some file instead of
% the screen, use: 
%
%     Output.place('fileName')
%
% or 
%
%     Output.place('fileName',true)
%
% when you want to replace the log file (beware not to use a file name
% that contains any kind of data, it will be replaced by the log
% file!!).
%
%     You can reset the output to the screen by doing:
%     
%     Output.place(1)
%
%   Finally, it may be used as a class of its on  
% 

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com> 


  enumeration
    DISP_VERBOSE(0)
    DISP_DEBUG(1)
    DISP_INFO(2)
    DISP_WARNING(3)
    MUTE(4)
  end

  properties
    mLvl
  end
  
  properties(Constant)
    methodLen = 30;
  end

  methods 
    function out = Output(lvl)
      out.mLvl = lvl;
    end
    function out = le(in1,in2)
      out = in1.mLvl <= in2.mLvl;
    end
  end

  methods (Static)
    function out = level(tLevel)
      persistent mLvl;
      if nargin > 0
        if(~isa(tLevel,'Output'))
          error('Output:level:WrongInputs',...
            'Argument tLevel must be an Output object.');
        else
          mLvl = tLevel;
        end
      end
      if isempty(mLvl)
        mLvl = Output.DISP_INFO;
      end
      if nargout == 1
        out = mLvl;
      end
    end

    function out = place(inPlace,replace)
      persistent mPlace;
      if isempty(mPlace)
        mPlace = 1;
      end
      if nargin > 0
        if nargin < 2
          replace = false;
        end
        if(ischar(inPlace))
          % Set new file using char
          try 
            if ~replace
              fExist = exist(inPlace,'file');
              if fExist
                warning('Output:place:FileExist',...
                  ['Tried to change output place, but file already'...
                  ' exists. If you want to replace it, use:\n\n'...
                  '   Output.place(''your_file_path'',true).\n\n'...
                  'Output will keep old output place.\n']);
                return
              end
              inPid=fopen(inPlace,'w');
            else
              inPid=fopen(inPlace,'w');
            end
          catch ext
            rethrow(ext);
          end
          % Close old file:
          try 
            switch mPlace
            case {1,2}
              % Do nothing
            otherwise
              fclose(mPlace);
            end
          catch ext
            warning(ext.getReport);
          end
          if inPid ~= mPlace
            % Reset any request for append message, if existent:
            Output.is_verbose_message_to_be_appended(false);
            Output.is_debug_message_to_be_appended(false);
            Output.is_info_message_to_be_appended(false);
          end
          mPlace = inPid;
        else
          switch inPlace
          case {1,2}
            if inPlace ~= mPlace
              % Reset any request for append message, if existent:
              Output.is_verbose_message_to_be_appended(false);
              Output.is_debug_message_to_be_appended(false);
              Output.is_info_message_to_be_appended(false);
            end
            mPlace = inPlace;
          otherwise
            warning('Output:place:WrongInput',...
              ['If you want to set output to a file, use its path '...
              'as input.']);
            return
          end
          try 
            % Close old file:
            switch mPlace
            case {1,2}
              % Do nothing
            otherwise
              fclose(mPlace);
            end
          catch ext
            warning(ext.getReport);
          end
        end
      end
      if nargout == 1
        out = mPlace;
      end
    end

    function VERBOSE(varargin)
      if Output.level<=Output.DISP_VERBOSE
        % Reset other level appendNextMessage and add newline:
        if Output.is_debug_message_to_be_appended || ...
            Output.is_info_message_to_be_appended
          fprintf(Output.place,'\n');
        end
        if nargin>0
          try
            mfile = dbstack; mfile = mfile(2).name;
          catch
            mfile = 'MATLAB.INTERPRETER';
          end
          len = numel(mfile);
          if len>Output.methodLen
            mfile = [mfile(1:Output.methodLen-3) ...
              '...'];
          else
            mfile = [mfile repmat(' ',1,...
              Output.methodLen-len)];
          end

          if Output.is_verbose_message_to_be_appended
            if nargin>1 && strcmp(varargin{end},'-appendNextMessage')
              Output.is_info_message_to_be_appended(true);
              varargin = varargin(1:end-1);
            else
              % Append new line if user did not used it on message end:
              if numel(varargin{1})<2 || ...
                  ~strcmp('\n',varargin{1}(end-1:end))
                varargin{1} = [varargin{1} '\n'];
              end
            end
            fprintf(Output.place,varargin{:});

          else

            if nargin>1
              if strcmp(varargin{end},'-appendNextMessage')
                Output.is_verbose_message_to_be_appended(true);
                varargin = varargin(1:end-1);
              else
                % Append new line if user did not used it on message end:
                if numel(varargin{1})<2 || ...
                    ~strcmp('\n',varargin{1}(end-1:end))
                  varargin{1} = [varargin{1} '\n'];
                end
              end
              fprintf(Output.place,['VERBOSE: ' mfile '\t' varargin{1}],...
                varargin{2:end});
            else
              % Append new line if user did not used it on message end:
              if numel(varargin{1})<2 || ...
                  ~strcmp('\n',varargin{1}(end-1:end))
                varargin{1} = [varargin{1} '\n'];
              end

              fprintf(Output.place,['VERBOSE: ' mfile '\t' varargin{1}]);
            end
          end
        else
          warning('Output:VERBOSE:WrongInputs',...
            'Too few inputs.');
        end
      end
    end

    function DEBUG(varargin)
      if Output.level<=Output.DISP_DEBUG
        % Reset other level appendNextMessage
        if Output.is_verbose_message_to_be_appended || ...
            Output.is_info_message_to_be_appended
          fprintf(Output.place,'\n');
        end
        if nargin>0
          try
            mfile = dbstack; mfile = mfile(2).name;
          catch
            mfile = 'MATLAB.INTERPRETER';
          end
          len = numel(mfile);
          if len>Output.methodLen
            mfile = [mfile(1:Output.methodLen-3) ...
            '...'];
          else
            mfile = [mfile repmat(' ',1,...
              Output.methodLen-len)];
          end

          if Output.is_debug_message_to_be_appended
            if nargin>1 && strcmp(varargin{end},'-appendNextMessage')
              Output.is_info_message_to_be_appended(true);
              varargin = varargin(1:end-1);
            else
              % Append new line if user did not used it on message end:
              if numel(varargin{1})<2 || ...
                  ~strcmp('\n',varargin{1}(end-1:end))
                varargin{1} = [varargin{1} '\n'];
              end
            end
            fprintf(Output.place,varargin{:});
          else

            if nargin>1
              if strcmp(varargin{end},'-appendNextMessage')
                Output.is_debug_message_to_be_appended(true);
                varargin = varargin(1:end-1);
              else
                % Append new line if user did not used it on message end:
                if numel(varargin{1})<2 || ...
                    ~strcmp('\n',varargin{1}(end-1:end))
                  varargin{1} = [varargin{1} '\n'];
                end
              end
              fprintf(Output.place,['DEBUG:   ' mfile '\t' ...
              varargin{1}],varargin{2:end});
            else

              % Append new line if user did not used it on message end:
              if numel(varargin{1})<2 || ...
                  ~strcmp('\n',varargin{1}(end-1:end))
                varargin{1} = [varargin{1} '\n'];
              end
              fprintf(Output.place,['DEBUG:   ' mfile '\t' ...
                varargin{1}]);
            end
          end
        else
          warning('Output:DEBUG:WrongInputs',...
            'Too few inputs.');
        end
      end
    end

    function INFO(varargin)
      if Output.level<=Output.DISP_INFO
        % Reset other level appendNextMessage
        if Output.is_verbose_message_to_be_appended || ...
            Output.is_debug_message_to_be_appended
          fprintf(Output.place,'\n');
        end
        if nargin>0
          try
            mfile = dbstack; mfile = mfile(2).name;
          catch
            mfile = 'MATLAB.INTERPRETER';
          end
          len = numel(mfile);
          if len>Output.methodLen
            mfile = [mfile(1:Output.methodLen-3) '...'];
          else
            mfile = [mfile repmat(' ',1,...
              Output.methodLen-len)];
          end



          if Output.is_info_message_to_be_appended
            if nargin>1 && strcmp(varargin{end},'-appendNextMessage')
              Output.is_info_message_to_be_appended(true);
              varargin = varargin(1:end-1);
            else
              % Append new line if user did not used it on message end:
              if numel(varargin{1})<2 || ...
                  ~strcmp('\n',varargin{1}(end-1:end))
                varargin{1} = [varargin{1} '\n'];
              end
            end
            fprintf(Output.place,varargin{:});

          else

            if nargin>1
              if strcmp(varargin{end},'-appendNextMessage')
                Output.is_info_message_to_be_appended(true);
                varargin = varargin(1:end-1);
              else
                % Append new line if user did not used it on message end:
                if numel(varargin{1})<2 || ...
                    ~strcmp('\n',varargin{1}(end-1:end))
                  varargin{1} = [varargin{1} '\n'];
                end
              end
              fprintf(Output.place,['INFO:    ' mfile '\t' varargin{1}],...
                varargin{2:end});
            else

              % Append new line if user did not used it on message end:
              if numel(varargin{1})<2 || ...
                  ~strcmp('\n',varargin{1}(end-1:end))
                varargin{1} = [varargin{1} '\n'];
              end
              fprintf(Output.place,['INFO:    ' mfile '\t' varargin{1}]);
            end
          end
        else
          warning('Output:INFO:WrongInputs',...
            'Too few inputs.');
        end
      end
    end


    function WARNING(varargin)
      if Output.level<=Output.DISP_WARNING
        % Reset other level appendNextMessage
        if Output.is_verbose_message_to_be_appended || ...
            Output.is_debug_message_to_be_appended || ...
            Output.is_info_message_to_be_appended
          fprintf(Output.place,'\n');
        end
        if nargin>0
          if nargin>2
            switch Output.place
            case {1,2}
              warning(varargin{1},varargin{2},varargin{3:end});
            otherwise
              try
                mfile = dbstack; mfile = mfile(2).name;
              catch
                mfile = 'MATLAB.INTERPRETER';
              end
              len = numel(mfile);
              if len>Output.methodLen
                mfile = [mfile(1:Output.methodLen-3) ...
                  '...'];
              else
                mfile = [mfile repmat(' ',1,...
                  Output.methodLen-len)];
              end
              fprintf(Output.place,['WARNING: ' mfile '\t'...
                varargin{2}],varargin{3:end});
            end
          elseif nargin==2
            switch Output.place
            case {1,2}
              warning(varargin{1},varargin{2});
            otherwise
              try
                mfile = dbstack; mfile = mfile(2).name;
              catch
                mfile = 'MATLAB.INTERPRETER';
              end
              len = numel(mfile);
              if len>Output.methodLen
                mfile = [mfile(1:Output.methodLen-3) ...
                  '...'];
              else
                mfile = [mfile repmat(' ',1,...
                  Output.methodLen-len)];
              end
              fprintf(Output.place,['WARNING: ' mfile '\t'...
                varargin{2}]);
            end
          else
            try
              mfile = dbstack; mfile = mfile(2).name;
            catch
              mfile = 'MATLAB.INTERPRETER';
            end
            len = numel(mfile);
            if len>Output.methodLen
              mfile = [mfile(1:Output.methodLen-3) ...
                '...'];
            else
              mfile = [mfile repmat(' ',1,...
                Output.methodLen-len)];
            end
            fprintf(Output.place,['WARNING: ' mfile '\t' varargin{1}]);
          end
        end
      end
    end

    function ERROR(varargin)
      if nargin>0
        % Reset other level appendNextMessage
        if Output.is_verbose_message_to_be_appended || ...
            Output.is_debug_message_to_be_appended || ...
            Output.is_info_message_to_be_appended
          fprintf(Output.place,'\n');
        end
        if nargin>2
          ext = MException(varargin{1},varargin{2},varargin{3:end});
          switch Output.place
          case {1,2}
            % Don't show, it will already print the message on screen.
          otherwise
            try
              mfile = dbstack; mfile = mfile(2).name;
            catch
              mfile = 'MATLAB.INTERPRETER';
            end
            len = numel(mfile);
            if len>Output.methodLen
              mfile = [mfile(1:Output.methodLen-3) ...
                '...'];
            else
              mfile = [mfile repmat(' ',1,...
                Output.methodLen-len)];
            end
            fprintf(Output.place,['ERROR:   ' mfile '\t' varargin{2}],...
              varargin{3:end});
          end
          ext.throwAsCaller;
        elseif nargin==2
          ext = MException(varargin{1},varargin{2});
          switch Output.place
          case {1,2}
            % Don't show, it will already print the message on screen.
          otherwise
            try
              mfile = dbstack; mfile = mfile(2).name;
            catch
              mfile = 'MATLAB.INTERPRETER';
            end
            len = numel(mfile);
            if len>Output.methodLen
              mfile = [mfile(1:Output.methodLen-3) ...
                '...'];
            else
              mfile = [mfile repmat(' ',1,...
                Output.methodLen-len)];
            end
            fprintf(Output.place,['ERROR:   ' mfile '\t' varargin{2}]);
          end
          ext.throwAsCaller;
        else
          ext = MException(varargin{1});
          try
            mfile = dbstack; mfile = mfile(2).name;
          catch
            mfile = 'MATLAB.INTERPRETER';
          end
          len = numel(mfile);
          if len>Output.methodLen
            mfile = [mfile(1:Output.methodLen-3) ...
              '...'];
          else
            mfile = [mfile repmat(' ',1,...
              Output.methodLen-len)];
          end
          fprintf(Output.place,['ERROR:   ' mfile '\t' varargin{1}]);
          ext.throwAsCaller;
        end
      end
    end
  end

  methods(Access = private,Static)

    function out = is_verbose_message_to_be_appended(tBool)
      % 
      % Set or check if next message will be appended or will be a new message.
      %   - mBool = 0: append next message.
      %   - mBool = 1: new full labeled message.
      %
      persistent mBool
      if nargin > 0
        mBool = tBool;
      end
      if isempty(mBool)
        mBool = false;
      end
      if nargout == 1
        out = mBool;
        mBool = false; % Reset it to new message
      end
    end

    function out = is_debug_message_to_be_appended(tBool)
      % 
      % Set or check if next message will be appended or will be a new message.
      %   - mBool = 0: append next message.
      %   - mBool = 1: new full labeled message.
      %
      persistent mBool
      if nargin > 0
        mBool = tBool;
      end
      if isempty(mBool)
        mBool = false;
      end
      if nargout == 1
        out = mBool;
        mBool = false; % Reset it to new message
      end
    end

    function out = is_info_message_to_be_appended(tBool)
      % 
      % Set or check if next message will be appended or will be a new message.
      %   - mBool = 0: append next message.
      %   - mBool = 1: new full labeled message.
      %
      persistent mBool
      if nargin > 0
        mBool = tBool;
      end
      if isempty(mBool)
        mBool = false;
      end
      if nargout == 1
        out = mBool;
        mBool = false; % Reset it to new message
      end
    end

  end

end

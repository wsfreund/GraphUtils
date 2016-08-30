function deleteHandle(handles)
%
% Package NILM_CEPEL.GraphUtils: Function deleteHandle 
%   Delete handle if it is valid.
%
%                         ------  Inputs  -------
%
% -> handles: The handles to delete.
%

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  if isempty(handles)
    %stack=dbstack('-completenames');
    %stack=sprintf('\t%s\n',stack.name);
    %  struct('type','.','subs','name');
    %Output.VERBOSE(['Attempt to delete empty handles.\n',...
    %  '\tCurrent stack is:\n%s'],stack);
    return
  end

  for k=1:numel(handles)
    if iscell(handles)
      curH = handles{k};
    else
      curH = handles(k);
    end
    if isempty(curH)
      continue
    end
    try
      if isnumeric(curH)
        curH=handle(curH);
      end
      if ( ishandle(curH) && ~strcmp(class(curH),'root') && ...
          ~strcmp(class(curH),'matlab.ui.Root') ) || ...
          (~isempty(regexp(class(curH),'^event\.(?>\w.*)','once')))
        Output.VERBOSE('Deleted object of type %s.\n',class(curH));
        delete(curH);
      else
        if ~strcmp(class(curH),'handle')
          stack=dbstack('-completenames');
          stack=sprintf('\t%s\n',stack.name);
            struct('type','.','subs','name');
          Output.DEBUG(...
            ['Object at position %d is not a handle. '...
            'Instead it is a: %s. Stack is:\n%s'],k,...
            class(curH),stack);
        end
      end
    catch ext
      % Get last segment of the error message identifier.
      idSegLast = regexp(ext.identifier, '(?<=:)\w+$',...
        'match'); 
      if strcmp(idSegLast, 'CannotDelete') 
        stack=dbstack('-completenames');
        stack=sprintf('\t%s\n',stack.name);
          struct('type','.','subs','name');
        Output.VERBOSE(['Attempt to delete empty handles.\n',...
          '\tCurrent stack is:\n%s'],stack);
      else
        rethrow(ext);
      end
    end
  end

end

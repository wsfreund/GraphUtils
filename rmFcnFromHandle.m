function rmFcnFromHandle(h,prop,fcn)
%
% Package NILM_CEPEL.GraphUtils: Function rmFcnFromHandle
%   Remove function to function handle list on property from an handle.
% 
% GraphUtils.addFcnToHandle(h,prop,fcn)
%
%                         ------  Inputs  -------
%
% -> h: handle to be modified
%
% -> prop: property to add the function
%
% -> fcn: function handle to be added.
%

% - Creation Date: Thu, 05 Sep 2013
% - Last Modified: Sun, 10 Aug 2014
% - Author(s): 
%   - W.S.Freund <wsfreund_at_gmail_dot_com>

  try
    fieldFcnVec=get(h,prop);
    if isa(fcn,'function_handle')
      fcn = func2str(fcn);
    end
    if iscell(fieldFcnVec)
      charFcn=cellfun(@ischar,fieldFcnVec);
      fieldFcnVec(~charFcn)=cellfun(@func2str,fieldFcnVec(~charFcn),...
        'UniformOutput',false);
    else
      if ~ischar(fieldFcnVec)
        fieldFcnVec={func2str(fieldFcnVec)};
      else
        fieldFcnVec={fieldFcnVec};
      end
    end
    rmIdx=find(cellfun(@(in) ~isempty(strfind(in,...
      fcn)),fieldFcnVec));
    if ~isempty(rmIdx)
      fieldFcnVec(rmIdx)=[];
      set(h,prop,fieldFcnVec);
    end
  catch ext
    Output.ERROR('NILM_CEPEL:GraphUtils:rmFcnFromHandle:CannotRemove',...
      'Could not remove function. Reason: %s',ext.getReport);
  end
end

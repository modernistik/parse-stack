
class Parse::User < Parse::Object
  # add additional properties

  # define a before save webhook for Parse::User
  # webhook :before_save do
  #   obj = parse_object # Parse::User
  #   # make changes to record....
  #   obj # will send the proper changelist back to Parse-Server
  # end

end

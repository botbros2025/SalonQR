DO $$ 
DECLARE 
  target_user_id uuid;
BEGIN
  -- 1. Get the user ID from auth.users based on the email
  SELECT id INTO target_user_id FROM auth.users WHERE email = 'iamst992@gmail.com';

  IF target_user_id IS NOT NULL THEN
    -- 2. Delete all child records associated with this user ID
    DELETE FROM public.user_roles WHERE user_id = target_user_id;
    DELETE FROM public.user_devices WHERE user_id = target_user_id;
    DELETE FROM public.user_sessions WHERE user_id = target_user_id;
    
    -- 3. Delete the public user profile
    DELETE FROM public.users WHERE id = target_user_id;
    
    -- 4. Finally, delete the auth record
    DELETE FROM auth.users WHERE id = target_user_id;
    
    RAISE NOTICE 'Successfully deleted all data for user %', target_user_id;
  ELSE
    RAISE NOTICE 'User not found!';
  END IF;
END $$;

-- Allow administrators (whitelisted emails) to manage all notifications and receipts
CREATE POLICY "Admins can manage all notifications" 
    ON public.notifications 
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users 
            WHERE email = auth.jwt() ->> 'email'
        )
    );

CREATE POLICY "Admins can manage all notification recipients" 
    ON public.notification_recipients 
    FOR ALL 
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.admin_users 
            WHERE email = auth.jwt() ->> 'email'
        )
    );

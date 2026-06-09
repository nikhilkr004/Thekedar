-- Trigger on public.applications (Bid request submissions & status updates)
CREATE OR REPLACE FUNCTION public.tr_on_application_change()
RETURNS TRIGGER AS $$
DECLARE
    v_project_title VARCHAR(255);
    v_customer_id UUID;
    v_contractor_user_id UUID;
BEGIN
    -- Resolve project details
    SELECT title, customer_id INTO v_project_title, v_customer_id 
    FROM public.projects WHERE id = NEW.project_id;
    
    -- Resolve contractor user_id
    SELECT user_id INTO v_contractor_user_id 
    FROM public.contractors WHERE id = NEW.contractor_id;

    IF (TG_OP = 'INSERT') THEN
        -- Notify customer that a contractor applied
        IF v_customer_id IS NOT NULL THEN
            PERFORM public.create_system_notification(
                NULL, 
                'New Application Received', 
                'A contractor has applied to your project: ' || v_project_title, 
                'project', 
                'medium', 
                v_customer_id
            );
        END IF;
    ELSIF (TG_OP = 'UPDATE') THEN
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            IF NEW.status = 'shortlisted' THEN
                PERFORM public.create_system_notification(
                    NULL, 
                    'Application Shortlisted', 
                    'Your application for "' || v_project_title || '" has been shortlisted!', 
                    'project', 
                    'high', 
                    v_contractor_user_id
                );
            ELSIF NEW.status = 'hired' THEN
                PERFORM public.create_system_notification(
                    NULL, 
                    'Application Hired', 
                    'Congratulations! You have been hired for the project: ' || v_project_title, 
                    'project', 
                    'high', 
                    v_contractor_user_id
                );
            ELSIF NEW.status = 'rejected' THEN
                PERFORM public.create_system_notification(
                    NULL, 
                    'Application Declined', 
                    'Your application for "' || v_project_title || '" was not selected.', 
                    'project', 
                    'low', 
                    v_contractor_user_id
                );
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_application_notification ON public.applications;
CREATE TRIGGER tr_application_notification
    AFTER INSERT OR UPDATE ON public.applications
    FOR EACH ROW EXECUTE FUNCTION public.tr_on_application_change();

-- Trigger on public.projects (Project completion notifications)
CREATE OR REPLACE FUNCTION public.tr_on_project_status_change()
RETURNS TRIGGER AS $$
DECLARE
    v_contractor_user_id UUID;
END;
$$;
-- Wait, let's write the complete function
CREATE OR REPLACE FUNCTION public.tr_on_project_status_change()
RETURNS TRIGGER AS $$
DECLARE
    v_contractor_user_id UUID;
BEGIN
    IF OLD.status IS DISTINCT FROM NEW.status THEN
        -- If project status changes to completed
        IF NEW.status = 'completed' THEN
            -- Notify Customer
            PERFORM public.create_system_notification(
                NULL, 
                'Project Completed', 
                'You have marked "' || NEW.title || '" as completed.', 
                'project', 
                'medium', 
                NEW.customer_id
            );
            
            -- Resolve contractor user_id if hired
            IF NEW.hired_contractor_id IS NOT NULL THEN
                SELECT user_id INTO v_contractor_user_id 
                FROM public.contractors WHERE id = NEW.hired_contractor_id;
                
                IF v_contractor_user_id IS NOT NULL THEN
                    PERFORM public.create_system_notification(
                        NULL, 
                        'Project Completed', 
                        'The project "' || NEW.title || '" has been completed. Thank you for your work!', 
                        'project', 
                        'high', 
                        v_contractor_user_id
                    );
                END IF;
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_project_status_notification ON public.projects;
CREATE TRIGGER tr_project_status_notification
    AFTER UPDATE ON public.projects
    FOR EACH ROW EXECUTE FUNCTION public.tr_on_project_status_change();

-- Trigger on public.messages (Realtime peer chat notifications)
CREATE OR REPLACE FUNCTION public.tr_on_message_inserted()
RETURNS TRIGGER AS $$
DECLARE
    v_sender_name VARCHAR(255);
    v_body TEXT;
BEGIN
    -- Resolve sender name
    SELECT full_name INTO v_sender_name 
    FROM public.users WHERE id = NEW.sender_id;
    
    -- Fallback to Email if full name not found
    IF v_sender_name IS NULL THEN
        SELECT email INTO v_sender_name 
        FROM auth.users WHERE id = NEW.sender_id;
    END IF;
    
    -- Setup preview message body
    v_body := NEW.content;
    IF length(v_body) > 60 THEN
        v_body := substring(v_body from 1 for 57) || '...';
    END IF;
    
    -- Send notification to recipient (receiver_id)
    IF NEW.receiver_id IS NOT NULL THEN
        PERFORM public.create_system_notification(
            NULL, 
            COALESCE(v_sender_name, 'New Message'), 
            v_body, 
            'chat', 
            'medium', 
            NEW.receiver_id
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tr_message_notification ON public.messages;
CREATE TRIGGER tr_message_notification
    AFTER INSERT ON public.messages
    FOR EACH ROW EXECUTE FUNCTION public.tr_on_message_inserted();

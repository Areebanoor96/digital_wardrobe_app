-- Add new relationship values to the existing enum.

ALTER TYPE public.relationship_type ADD VALUE IF NOT EXISTS 'mother';
ALTER TYPE public.relationship_type ADD VALUE IF NOT EXISTS 'father';
ALTER TYPE public.relationship_type ADD VALUE IF NOT EXISTS 'brother';
ALTER TYPE public.relationship_type ADD VALUE IF NOT EXISTS 'sister';
ALTER TYPE public.relationship_type ADD VALUE IF NOT EXISTS 'grandparent';
ALTER TYPE public.relationship_type ADD VALUE IF NOT EXISTS 'cousin';


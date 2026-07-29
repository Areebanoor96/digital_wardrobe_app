drop view if exists public.v_cost_per_wear;

create view public.v_cost_per_wear as
select
  g.id,
  g.user_id,
  g.member_id,
  g.name,
  g.price,
  g.wear_count,
  case
    when g.wear_count = 0 then g.price
    else round(g.price / g.wear_count, 2)
  end as cost_per_wear
from public.garments g
where g.is_archived = false
  and g.price is not null;


drop view if exists public.v_wardrobe_stats;

create view public.v_wardrobe_stats as
select
  g.user_id,
  g.member_id,
  count(*) as total_items,
  sum(g.price) as total_value,
  round(
    avg(
      case
        when g.wear_count = 0 then g.price
        else g.price / g.wear_count
      end
    ),
    2
  ) as avg_cpw,
  round(avg(g.eco_score)) as avg_eco_score
from public.garments g
where g.is_archived = false
group by
  g.user_id,
  g.member_id;
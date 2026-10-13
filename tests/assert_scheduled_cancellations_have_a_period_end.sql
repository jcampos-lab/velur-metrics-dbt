-- A subscription set to cancel at the end of its paid period must say when that period ends.
-- Without it there is no honest last billing day, so the build stops instead of guessing.

select subscriptions.id
from {{ source('stripe', 'subscriptions') }} as subscriptions
left join {{ source('stripe', 'subscription_items') }} as items
    on items.subscription_id = subscriptions.id
where cast(subscriptions.cancel_at_period_end as boolean)
group by subscriptions.id
having count(items.current_period_end) = 0

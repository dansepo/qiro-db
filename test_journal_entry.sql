-- 생성된 분개 전표 확인
SELECT 
    je.entry_id,
    je.entry_number,
    je.entry_date,
    je.description,
    je.total_amount,
    je.status
FROM journal_entries je
WHERE je.company_id = 'f47ac10b-58cc-4372-a567-0e02b2c3d479'::UUID
ORDER BY je.created_at DESC
LIMIT 5;
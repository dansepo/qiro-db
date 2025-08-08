package com.qiro.domain.dashboard.repository

import com.qiro.domain.dashboard.dto.*
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate
import org.springframework.stereotype.Repository
import java.time.LocalDateTime
import java.util.*

/**
 * 대시보드 데이터 조회를 위한 Repository 구현체
 */
@Repository
class DashboardRepositoryImpl(
    private val namedParameterJdbcTemplate: NamedParameterJdbcTemplate
) : DashboardRepository {
    
    override fun getDashboardOverview(companyId: UUID): DashboardOverviewDto? {
        val sql = """
            SELECT 
                company_id,
                company_name,
                total_assets,
                active_assets,
                maintenance_assets,
                out_of_order_assets,
                total_fault_reports,
                new_reports,
                in_progress_reports,
                completed_reports,
                emergency_reports,
                total_work_orders,
                assigned_work_orders,
                in_progress_work_orders,
                completed_work_orders,
                overdue_work_orders,
                total_maintenance_plans,
                due_maintenance,
                upcoming_maintenance,
                monthly_cost,
                yearly_cost,
                last_updated
            FROM bms.v_facility_dashboard_overview
            WHERE company_id = :companyId
        """.trimIndent()
        
        val params = mapOf("companyId" to companyId)
        
        return try {
            namedParameterJdbcTemplate.queryForObject(sql, params) { rs, _ ->
                DashboardOverviewDto(
                    companyId = UUID.fromString(rs.getString("company_id")),
                    companyName = rs.getString("company_name"),
                    totalAssets = rs.getLong("total_assets"),
                    activeAssets = rs.getLong("active_assets"),
                    maintenanceAssets = rs.getLong("maintenance_assets"),
                    outOfOrderAssets = rs.getLong("out_of_order_assets"),
                    totalFaultReports = rs.getLong("total_fault_reports"),
                    newReports = rs.getLong("new_reports"),
                    inProgressReports = rs.getLong("in_progress_reports"),
                    completedReports = rs.getLong("completed_reports"),
                    emergencyReports = rs.getLong("emergency_reports"),
                    totalWorkOrders = rs.getLong("total_work_orders"),
                    assignedWorkOrders = rs.getLong("assigned_work_orders"),
                    inProgressWorkOrders = rs.getLong("in_progress_work_orders"),
                    completedWorkOrders = rs.getLong("completed_work_orders"),
                    overdueWorkOrders = rs.getLong("overdue_work_orders"),
                    totalMaintenancePlans = rs.getLong("total_maintenance_plans"),
                    dueMaintenance = rs.getLong("due_maintenance"),
                    upcomingMaintenance = rs.getLong("upcoming_maintenance"),
                    monthlyCost = rs.getDouble("monthly_cost"),
                    yearlyCost = rs.getDouble("yearly_cost"),
                    lastUpdated = rs.getTimestamp("last_updated").toLocalDateTime()
                )
            }
        } catch (e: Exception) {
            null
        }
    }
    
    override fun getDashboardKpi(companyId: UUID): DashboardKpiDto? {
        val sql = """
            SELECT 
                company_id,
                company_name,
                total_assets,
                active_assets,
                avg_uptime_percentage,
                total_reports_this_month,
                total_work_orders_this_month,
                total_cost_this_month,
                excellent_assets,
                good_assets,
                fair_assets,
                poor_assets,
                last_updated
            FROM bms.v_facility_dashboard_kpi
            WHERE company_id = :companyId
        """.trimIndent()
        
        val params = mapOf("companyId" to companyId)
        
        return try {
            namedParameterJdbcTemplate.queryForObject(sql, params) { rs, _ ->
                DashboardKpiDto(
                    companyId = UUID.fromString(rs.getString("company_id")),
                    companyName = rs.getString("company_name"),
                    totalAssets = rs.getLong("total_assets"),
                    activeAssets = rs.getLong("active_assets"),
                    avgUptimePercentage = rs.getDouble("avg_uptime_percentage"),
                    totalReportsThisMonth = rs.getLong("total_reports_this_month"),
                    totalWorkOrdersThisMonth = rs.getLong("total_work_orders_this_month"),
                    totalCostThisMonth = rs.getDouble("total_cost_this_month"),
                    excellentAssets = rs.getLong("excellent_assets"),
                    goodAssets = rs.getLong("good_assets"),
                    fairAssets = rs.getLong("fair_assets"),
                    poorAssets = rs.getLong("poor_assets"),
                    lastUpdated = rs.getTimestamp("last_updated").toLocalDateTime()
                )
            }
        } catch (e: Exception) {
            null
        }
    }
    
    override fun getMonthlyFacilityReport(companyId: UUID): MonthlyFacilityReportDto? {
        val sql = """
            SELECT 
                company_id,
                company_name,
                report_month,
                total_fault_reports,
                emergency_reports,
                high_priority_reports,
                resolved_reports,
                avg_resolution_time_hours,
                total_work_orders,
                preventive_work_orders,
                corrective_work_orders,
                emergency_work_orders,
                total_maintenance_cost,
                labor_cost,
                material_cost,
                contractor_cost,
                total_assets,
                active_assets,
                excellent_condition_assets,
                good_condition_assets,
                fair_condition_assets,
                poor_condition_assets,
                total_maintenance_plans,
                completed_maintenance,
                overdue_maintenance,
                generated_at
            FROM bms.v_monthly_facility_report
            WHERE company_id = :companyId
        """.trimIndent()
        
        val params = mapOf("companyId" to companyId)
        
        return try {
            namedParameterJdbcTemplate.queryForObject(sql, params) { rs, _ ->
                MonthlyFacilityReportDto(
                    companyId = UUID.fromString(rs.getString("company_id")),
                    companyName = rs.getString("company_name"),
                    reportMonth = rs.getTimestamp("report_month").toLocalDateTime(),
                    totalFaultReports = rs.getLong("total_fault_reports"),
                    emergencyReports = rs.getLong("emergency_reports"),
                    highPriorityReports = rs.getLong("high_priority_reports"),
                    resolvedReports = rs.getLong("resolved_reports"),
                    avgResolutionTimeHours = rs.getDouble("avg_resolution_time_hours"),
                    totalWorkOrders = rs.getLong("total_work_orders"),
                    preventiveWorkOrders = rs.getLong("preventive_work_orders"),
                    correctiveWorkOrders = rs.getLong("corrective_work_orders"),
                    emergencyWorkOrders = rs.getLong("emergency_work_orders"),
                    totalMaintenanceCost = rs.getDouble("total_maintenance_cost"),
                    laborCost = rs.getDouble("labor_cost"),
                    materialCost = rs.getDouble("material_cost"),
                    contractorCost = rs.getDouble("contractor_cost"),
                    totalAssets = rs.getLong("total_assets"),
                    activeAssets = rs.getLong("active_assets"),
                    excellentConditionAssets = rs.getLong("excellent_condition_assets"),
                    goodConditionAssets = rs.getLong("good_condition_assets"),
                    fairConditionAssets = rs.getLong("fair_condition_assets"),
                    poorConditionAssets = rs.getLong("poor_condition_assets"),
                    totalMaintenancePlans = rs.getLong("total_maintenance_plans"),
                    completedMaintenance = rs.getLong("completed_maintenance"),
                    overdueMaintenance = rs.getLong("overdue_maintenance"),
                    generatedAt = rs.getTimestamp("generated_at").toLocalDateTime()
                )
            }
        } catch (e: Exception) {
            null
        }
    }
    
    override fun getCostAnalysisReport(companyId: UUID): CostAnalysisReportDto? {
        val sql = """
            SELECT 
                company_id,
                company_name,
                weekly_cost,
                monthly_cost,
                quarterly_cost,
                yearly_cost,
                total_labor_cost,
                total_material_cost,
                total_contractor_cost,
                total_equipment_cost,
                preventive_maintenance_cost,
                corrective_maintenance_cost,
                emergency_repair_cost,
                electrical_cost,
                plumbing_cost,
                hvac_cost,
                elevator_cost,
                fire_safety_cost,
                avg_cost_per_work_order,
                total_cost_entries,
                highest_single_cost,
                lowest_single_cost,
                generated_at
            FROM bms.v_cost_analysis_report
            WHERE company_id = :companyId
        """.trimIndent()
        
        val params = mapOf("companyId" to companyId)
        
        return try {
            namedParameterJdbcTemplate.queryForObject(sql, params) { rs, _ ->
                CostAnalysisReportDto(
                    companyId = UUID.fromString(rs.getString("company_id")),
                    companyName = rs.getString("company_name"),
                    weeklyCost = rs.getDouble("weekly_cost"),
                    monthlyCost = rs.getDouble("monthly_cost"),
                    quarterlyCost = rs.getDouble("quarterly_cost"),
                    yearlyCost = rs.getDouble("yearly_cost"),
                    totalLaborCost = rs.getDouble("total_labor_cost"),
                    totalMaterialCost = rs.getDouble("total_material_cost"),
                    totalContractorCost = rs.getDouble("total_contractor_cost"),
                    totalEquipmentCost = rs.getDouble("total_equipment_cost"),
                    preventiveMaintenanceCost = rs.getDouble("preventive_maintenance_cost"),
                    correctiveMaintenanceCost = rs.getDouble("corrective_maintenance_cost"),
                    emergencyRepairCost = rs.getDouble("emergency_repair_cost"),
                    electricalCost = rs.getDouble("electrical_cost"),
                    plumbingCost = rs.getDouble("plumbing_cost"),
                    hvacCost = rs.getDouble("hvac_cost"),
                    elevatorCost = rs.getDouble("elevator_cost"),
                    fireSafetyCost = rs.getDouble("fire_safety_cost"),
                    avgCostPerWorkOrder = rs.getDouble("avg_cost_per_work_order"),
                    totalCostEntries = rs.getLong("total_cost_entries"),
                    highestSingleCost = rs.getDouble("highest_single_cost"),
                    lowestSingleCost = rs.getDouble("lowest_single_cost"),
                    generatedAt = rs.getTimestamp("generated_at").toLocalDateTime()
                )
            }
        } catch (e: Exception) {
            null
        }
    }
    
    override fun getFacilityAlerts(companyId: UUID): FacilityAlertsDto? {
        val sql = """
            SELECT 
                company_id,
                company_name,
                active_emergency_reports,
                active_emergency_work_orders,
                overdue_work_orders,
                overdue_maintenance,
                warranty_expiring_soon,
                warranty_expired,
                low_performance_assets,
                poor_condition_assets,
                budget_risk_level,
                generated_at
            FROM bms.v_facility_alerts_dashboard
            WHERE company_id = :companyId
        """.trimIndent()
        
        val params = mapOf("companyId" to companyId)
        
        return try {
            namedParameterJdbcTemplate.queryForObject(sql, params) { rs, _ ->
                FacilityAlertsDto(
                    companyId = UUID.fromString(rs.getString("company_id")),
                    companyName = rs.getString("company_name"),
                    activeEmergencyReports = rs.getLong("active_emergency_reports"),
                    activeEmergencyWorkOrders = rs.getLong("active_emergency_work_orders"),
                    overdueWorkOrders = rs.getLong("overdue_work_orders"),
                    overdueMaintenance = rs.getLong("overdue_maintenance"),
                    warrantyExpiringSoon = rs.getLong("warranty_expiring_soon"),
                    warrantyExpired = rs.getLong("warranty_expired"),
                    lowPerformanceAssets = rs.getLong("low_performance_assets"),
                    poorConditionAssets = rs.getLong("poor_condition_assets"),
                    budgetRiskLevel = rs.getString("budget_risk_level"),
                    generatedAt = rs.getTimestamp("generated_at").toLocalDateTime()
                )
            }
        } catch (e: Exception) {
            null
        }
    }
    
    override fun getWidgetData(
        companyId: UUID,
        widgetType: String,
        filterConfig: Map<String, Any>?
    ): WidgetDataDto? {
        val sql = "SELECT bms.get_widget_data(:companyId, :widgetType, :filterConfig::jsonb) as widget_data"
        
        val params = mapOf(
            "companyId" to companyId,
            "widgetType" to widgetType,
            "filterConfig" to (filterConfig?.let { 
                com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(it) 
            } ?: "{}")
        )
        
        return try {
            namedParameterJdbcTemplate.queryForObject(sql, params) { rs, _ ->
                val jsonData = rs.getString("widget_data")
                val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
                val dataMap = objectMapper.readValue(jsonData, Map::class.java)
                
                WidgetDataDto(
                    widgetType = widgetType,
                    data = dataMap,
                    lastUpdated = LocalDateTime.now()
                )
            }
        } catch (e: Exception) {
            null
        }
    }
    
    override fun refreshDashboardData(
        companyId: UUID,
        dashboardType: String?
    ): Map<String, Any> {
        val sql = "SELECT bms.refresh_dashboard_data(:companyId, :dashboardType) as dashboard_data"
        
        val params = mapOf(
            "companyId" to companyId,
            "dashboardType" to dashboardType
        )
        
        return try {
            namedParameterJdbcTemplate.queryForObject(sql, params) { rs, _ ->
                val jsonData = rs.getString("dashboard_data")
                val objectMapper = com.fasterxml.jackson.databind.ObjectMapper()
                objectMapper.readValue(jsonData, Map::class.java) as Map<String, Any>
            } ?: emptyMap()
        } catch (e: Exception) {
            emptyMap()
        }
    }
}
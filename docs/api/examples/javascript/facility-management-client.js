/**
 * 시설 관리 시스템 JavaScript 클라이언트
 * 
 * 사용법:
 * const client = new FacilityManagementClient('https://api.qiro.com');
 * await client.login('user@example.com', 'password');
 * const faultReports = await client.getFaultReports();
 */

class FacilityManagementClient {
    constructor(baseUrl = 'https://api.qiro.com') {
        this.baseUrl = baseUrl;
        this.token = null;
        this.refreshToken = null;
    }

    /**
     * 로그인
     */
    async login(username, password) {
        const response = await this.request('POST', '/api/v1/auth/login', {
            username,
            password
        });

        if (response.success) {
            this.token = response.data.accessToken;
            this.refreshToken = response.data.refreshToken;
            return response.data.user;
        }

        throw new Error(response.message);
    }

    /**
     * 로그아웃
     */
    async logout() {
        if (this.token) {
            await this.request('POST', '/api/v1/auth/logout');
        }
        this.token = null;
        this.refreshToken = null;
    }

    /**
     * 토큰 갱신
     */
    async refreshAccessToken() {
        if (!this.refreshToken) {
            throw new Error('Refresh token not available');
        }

        const response = await this.request('POST', '/api/v1/auth/refresh', {
            refreshToken: this.refreshToken
        });

        if (response.success) {
            this.token = response.data.accessToken;
            return this.token;
        }

        throw new Error('Token refresh failed');
    }

    /**
     * 고장 신고 목록 조회
     */
    async getFaultReports(options = {}) {
        const params = new URLSearchParams();
        
        if (options.page !== undefined) params.append('page', options.page);
        if (options.size !== undefined) params.append('size', options.size);
        if (options.status) params.append('status', options.status);
        if (options.priority) params.append('priority', options.priority);
        if (options.search) params.append('search', options.search);
        if (options.sort) params.append('sort', options.sort);

        const url = `/api/v1/fault-reports${params.toString() ? '?' + params.toString() : ''}`;
        const response = await this.request('GET', url);

        return response.success ? response.data : null;
    }

    /**
     * 고장 신고 상세 조회
     */
    async getFaultReport(id) {
        const response = await this.request('GET', `/api/v1/fault-reports/${id}`);
        return response.success ? response.data : null;
    }

    /**
     * 고장 신고 생성
     */
    async createFaultReport(data) {
        const response = await this.request('POST', '/api/v1/fault-reports', data);
        return response.success ? response.data : null;
    }

    /**
     * 고장 신고 수정
     */
    async updateFaultReport(id, data) {
        const response = await this.request('PUT', `/api/v1/fault-reports/${id}`, data);
        return response.success ? response.data : null;
    }

    /**
     * 작업 지시서 목록 조회
     */
    async getWorkOrders(options = {}) {
        const params = new URLSearchParams();
        
        if (options.page !== undefined) params.append('page', options.page);
        if (options.size !== undefined) params.append('size', options.size);
        if (options.status) params.append('status', options.status);
        if (options.assignedTo) params.append('assignedTo', options.assignedTo);
        if (options.workType) params.append('workType', options.workType);

        const url = `/api/v1/work-orders${params.toString() ? '?' + params.toString() : ''}`;
        const response = await this.request('GET', url);

        return response.success ? response.data : null;
    }

    /**
     * 작업 지시서 생성
     */
    async createWorkOrder(data) {
        const response = await this.request('POST', '/api/v1/work-orders', data);
        return response.success ? response.data : null;
    }

    /**
     * 작업 상태 업데이트
     */
    async updateWorkOrderStatus(id, status, notes = null) {
        const data = { status };
        if (notes) data.notes = notes;

        const response = await this.request('PATCH', `/api/v1/work-orders/${id}/status`, data);
        return response.success ? response.data : null;
    }

    /**
     * 예방 정비 계획 목록 조회
     */
    async getMaintenancePlans(options = {}) {
        const params = new URLSearchParams();
        
        if (options.page !== undefined) params.append('page', options.page);
        if (options.size !== undefined) params.append('size', options.size);
        if (options.assetId) params.append('assetId', options.assetId);
        if (options.planStatus) params.append('planStatus', options.planStatus);

        const url = `/api/v1/maintenance/plans${params.toString() ? '?' + params.toString() : ''}`;
        const response = await this.request('GET', url);

        return response.success ? response.data : null;
    }

    /**
     * 예방 정비 계획 생성
     */
    async createMaintenancePlan(data) {
        const response = await this.request('POST', '/api/v1/maintenance/plans', data);
        return response.success ? response.data : null;
    }

    /**
     * 대시보드 데이터 조회
     */
    async getDashboard() {
        const response = await this.request('GET', '/api/v1/dashboard/facility-overview');
        return response.success ? response.data : null;
    }

    /**
     * 파일 업로드
     */
    async uploadFile(file, entityType, entityId) {
        const formData = new FormData();
        formData.append('file', file);
        formData.append('entityType', entityType);
        formData.append('entityId', entityId);

        const response = await fetch(`${this.baseUrl}/api/v1/attachments/upload`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${this.token}`
            },
            body: formData
        });

        const result = await response.json();
        return result.success ? result.data : null;
    }

    /**
     * 알림 목록 조회
     */
    async getNotifications(options = {}) {
        const params = new URLSearchParams();
        
        if (options.page !== undefined) params.append('page', options.page);
        if (options.size !== undefined) params.append('size', options.size);
        if (options.unreadOnly) params.append('unreadOnly', 'true');

        const url = `/api/v1/notifications${params.toString() ? '?' + params.toString() : ''}`;
        const response = await this.request('GET', url);

        return response.success ? response.data : null;
    }

    /**
     * 알림 읽음 처리
     */
    async markNotificationAsRead(id) {
        const response = await this.request('PATCH', `/api/v1/notifications/${id}/read`);
        return response.success;
    }

    /**
     * 통계 데이터 조회
     */
    async getStatistics(type, period = 'month') {
        const response = await this.request('GET', `/api/v1/statistics/${type}?period=${period}`);
        return response.success ? response.data : null;
    }

    /**
     * HTTP 요청 헬퍼
     */
    async request(method, url, data = null, retryCount = 0) {
        const options = {
            method,
            headers: {
                'Content-Type': 'application/json'
            }
        };

        if (this.token) {
            options.headers['Authorization'] = `Bearer ${this.token}`;
        }

        if (data && (method === 'POST' || method === 'PUT' || method === 'PATCH')) {
            options.body = JSON.stringify(data);
        }

        try {
            const response = await fetch(`${this.baseUrl}${url}`, options);
            const result = await response.json();

            // 토큰 만료 시 자동 갱신 시도
            if (response.status === 401 && retryCount === 0 && this.refreshToken) {
                try {
                    await this.refreshAccessToken();
                    return this.request(method, url, data, retryCount + 1);
                } catch (refreshError) {
                    // 토큰 갱신 실패 시 로그아웃 처리
                    this.token = null;
                    this.refreshToken = null;
                    throw new Error('Authentication failed');
                }
            }

            return result;
        } catch (error) {
            console.error('API request failed:', error);
            throw error;
        }
    }
}

// 사용 예제
async function example() {
    const client = new FacilityManagementClient('https://api-dev.qiro.com');

    try {
        // 로그인
        const user = await client.login('manager@example.com', 'password123');
        console.log('로그인 성공:', user);

        // 고장 신고 목록 조회
        const faultReports = await client.getFaultReports({
            page: 0,
            size: 10,
            status: 'OPEN',
            sort: 'createdAt,desc'
        });
        console.log('고장 신고 목록:', faultReports);

        // 새 고장 신고 생성
        const newFaultReport = await client.createFaultReport({
            title: '엘리베이터 고장',
            description: '1층 엘리베이터가 작동하지 않습니다',
            assetId: '123e4567-e89b-12d3-a456-426614174000',
            priority: 'HIGH',
            location: '1층 로비'
        });
        console.log('새 고장 신고:', newFaultReport);

        // 작업 지시서 생성
        const workOrder = await client.createWorkOrder({
            title: '엘리베이터 수리',
            description: '엘리베이터 모터 점검 및 수리',
            faultReportId: newFaultReport.id,
            workType: 'REPAIR',
            priority: 'HIGH',
            assignedTo: '456e7890-e89b-12d3-a456-426614174000'
        });
        console.log('작업 지시서:', workOrder);

        // 대시보드 데이터 조회
        const dashboard = await client.getDashboard();
        console.log('대시보드:', dashboard);

    } catch (error) {
        console.error('오류 발생:', error);
    }
}

// Node.js 환경에서 사용 시
if (typeof module !== 'undefined' && module.exports) {
    module.exports = FacilityManagementClient;
}

// 브라우저 환경에서 사용 시
if (typeof window !== 'undefined') {
    window.FacilityManagementClient = FacilityManagementClient;
}
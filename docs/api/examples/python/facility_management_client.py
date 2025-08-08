"""
시설 관리 시스템 Python 클라이언트

사용법:
    from facility_management_client import FacilityManagementClient
    
    client = FacilityManagementClient('https://api.qiro.com')
    await client.login('user@example.com', 'password')
    fault_reports = await client.get_fault_reports()
"""

import asyncio
import aiohttp
import json
from typing import Optional, Dict, List, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class FacilityManagementClient:
    """시설 관리 시스템 API 클라이언트"""
    
    def __init__(self, base_url: str = 'https://api.qiro.com'):
        self.base_url = base_url.rstrip('/')
        self.token: Optional[str] = None
        self.refresh_token: Optional[str] = None
        self.session: Optional[aiohttp.ClientSession] = None
    
    async def __aenter__(self):
        """비동기 컨텍스트 매니저 진입"""
        self.session = aiohttp.ClientSession()
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        """비동기 컨텍스트 매니저 종료"""
        if self.session:
            await self.session.close()
    
    async def login(self, username: str, password: str) -> Dict[str, Any]:
        """로그인"""
        data = {
            'username': username,
            'password': password
        }
        
        response = await self._request('POST', '/api/v1/auth/login', data)
        
        if response['success']:
            self.token = response['data']['accessToken']
            self.refresh_token = response['data']['refreshToken']
            return response['data']['user']
        
        raise Exception(response['message'])
    
    async def logout(self) -> None:
        """로그아웃"""
        if self.token:
            await self._request('POST', '/api/v1/auth/logout')
        
        self.token = None
        self.refresh_token = None
    
    async def refresh_access_token(self) -> str:
        """토큰 갱신"""
        if not self.refresh_token:
            raise Exception('Refresh token not available')
        
        data = {'refreshToken': self.refresh_token}
        response = await self._request('POST', '/api/v1/auth/refresh', data)
        
        if response['success']:
            self.token = response['data']['accessToken']
            return self.token
        
        raise Exception('Token refresh failed')
    
    async def get_fault_reports(self, **options) -> Optional[Dict[str, Any]]:
        """고장 신고 목록 조회"""
        params = {}
        
        for key in ['page', 'size', 'status', 'priority', 'search', 'sort']:
            if key in options:
                params[key] = options[key]
        
        url = '/api/v1/fault-reports'
        if params:
            param_str = '&'.join([f'{k}={v}' for k, v in params.items()])
            url += f'?{param_str}'
        
        response = await self._request('GET', url)
        return response['data'] if response['success'] else None
    
    async def get_fault_report(self, report_id: str) -> Optional[Dict[str, Any]]:
        """고장 신고 상세 조회"""
        response = await self._request('GET', f'/api/v1/fault-reports/{report_id}')
        return response['data'] if response['success'] else None
    
    async def create_fault_report(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """고장 신고 생성"""
        response = await self._request('POST', '/api/v1/fault-reports', data)
        return response['data'] if response['success'] else None
    
    async def update_fault_report(self, report_id: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """고장 신고 수정"""
        response = await self._request('PUT', f'/api/v1/fault-reports/{report_id}', data)
        return response['data'] if response['success'] else None
    
    async def get_work_orders(self, **options) -> Optional[Dict[str, Any]]:
        """작업 지시서 목록 조회"""
        params = {}
        
        for key in ['page', 'size', 'status', 'assignedTo', 'workType']:
            if key in options:
                params[key] = options[key]
        
        url = '/api/v1/work-orders'
        if params:
            param_str = '&'.join([f'{k}={v}' for k, v in params.items()])
            url += f'?{param_str}'
        
        response = await self._request('GET', url)
        return response['data'] if response['success'] else None
    
    async def create_work_order(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """작업 지시서 생성"""
        response = await self._request('POST', '/api/v1/work-orders', data)
        return response['data'] if response['success'] else None
    
    async def update_work_order_status(self, work_order_id: str, status: str, notes: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """작업 상태 업데이트"""
        data = {'status': status}
        if notes:
            data['notes'] = notes
        
        response = await self._request('PATCH', f'/api/v1/work-orders/{work_order_id}/status', data)
        return response['data'] if response['success'] else None
    
    async def get_maintenance_plans(self, **options) -> Optional[Dict[str, Any]]:
        """예방 정비 계획 목록 조회"""
        params = {}
        
        for key in ['page', 'size', 'assetId', 'planStatus']:
            if key in options:
                params[key] = options[key]
        
        url = '/api/v1/maintenance/plans'
        if params:
            param_str = '&'.join([f'{k}={v}' for k, v in params.items()])
            url += f'?{param_str}'
        
        response = await self._request('GET', url)
        return response['data'] if response['success'] else None
    
    async def create_maintenance_plan(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """예방 정비 계획 생성"""
        response = await self._request('POST', '/api/v1/maintenance/plans', data)
        return response['data'] if response['success'] else None
    
    async def get_dashboard(self) -> Optional[Dict[str, Any]]:
        """대시보드 데이터 조회"""
        response = await self._request('GET', '/api/v1/dashboard/facility-overview')
        return response['data'] if response['success'] else None
    
    async def upload_file(self, file_path: str, entity_type: str, entity_id: str) -> Optional[Dict[str, Any]]:
        """파일 업로드"""
        if not self.session:
            raise Exception('Session not initialized')
        
        data = aiohttp.FormData()
        data.add_field('file', open(file_path, 'rb'))
        data.add_field('entityType', entity_type)
        data.add_field('entityId', entity_id)
        
        headers = {}
        if self.token:
            headers['Authorization'] = f'Bearer {self.token}'
        
        async with self.session.post(
            f'{self.base_url}/api/v1/attachments/upload',
            data=data,
            headers=headers
        ) as response:
            result = await response.json()
            return result['data'] if result['success'] else None
    
    async def get_notifications(self, **options) -> Optional[Dict[str, Any]]:
        """알림 목록 조회"""
        params = {}
        
        for key in ['page', 'size']:
            if key in options:
                params[key] = options[key]
        
        if options.get('unread_only'):
            params['unreadOnly'] = 'true'
        
        url = '/api/v1/notifications'
        if params:
            param_str = '&'.join([f'{k}={v}' for k, v in params.items()])
            url += f'?{param_str}'
        
        response = await self._request('GET', url)
        return response['data'] if response['success'] else None
    
    async def mark_notification_as_read(self, notification_id: str) -> bool:
        """알림 읽음 처리"""
        response = await self._request('PATCH', f'/api/v1/notifications/{notification_id}/read')
        return response['success']
    
    async def get_statistics(self, stat_type: str, period: str = 'month') -> Optional[Dict[str, Any]]:
        """통계 데이터 조회"""
        response = await self._request('GET', f'/api/v1/statistics/{stat_type}?period={period}')
        return response['data'] if response['success'] else None
    
    async def _request(self, method: str, url: str, data: Optional[Dict[str, Any]] = None, retry_count: int = 0) -> Dict[str, Any]:
        """HTTP 요청 헬퍼"""
        if not self.session:
            raise Exception('Session not initialized')
        
        headers = {'Content-Type': 'application/json'}
        if self.token:
            headers['Authorization'] = f'Bearer {self.token}'
        
        kwargs = {
            'headers': headers
        }
        
        if data and method in ['POST', 'PUT', 'PATCH']:
            kwargs['json'] = data
        
        try:
            async with self.session.request(method, f'{self.base_url}{url}', **kwargs) as response:
                result = await response.json()
                
                # 토큰 만료 시 자동 갱신 시도
                if response.status == 401 and retry_count == 0 and self.refresh_token:
                    try:
                        await self.refresh_access_token()
                        return await self._request(method, url, data, retry_count + 1)
                    except Exception as refresh_error:
                        # 토큰 갱신 실패 시 로그아웃 처리
                        self.token = None
                        self.refresh_token = None
                        raise Exception('Authentication failed') from refresh_error
                
                return result
        
        except Exception as error:
            logger.error(f'API request failed: {error}')
            raise


# 사용 예제
async def example():
    """사용 예제"""
    async with FacilityManagementClient('https://api-dev.qiro.com') as client:
        try:
            # 로그인
            user = await client.login('manager@example.com', 'password123')
            print(f'로그인 성공: {user}')
            
            # 고장 신고 목록 조회
            fault_reports = await client.get_fault_reports(
                page=0,
                size=10,
                status='OPEN',
                sort='createdAt,desc'
            )
            print(f'고장 신고 목록: {fault_reports}')
            
            # 새 고장 신고 생성
            new_fault_report = await client.create_fault_report({
                'title': '엘리베이터 고장',
                'description': '1층 엘리베이터가 작동하지 않습니다',
                'assetId': '123e4567-e89b-12d3-a456-426614174000',
                'priority': 'HIGH',
                'location': '1층 로비'
            })
            print(f'새 고장 신고: {new_fault_report}')
            
            # 작업 지시서 생성
            work_order = await client.create_work_order({
                'title': '엘리베이터 수리',
                'description': '엘리베이터 모터 점검 및 수리',
                'faultReportId': new_fault_report['id'],
                'workType': 'REPAIR',
                'priority': 'HIGH',
                'assignedTo': '456e7890-e89b-12d3-a456-426614174000'
            })
            print(f'작업 지시서: {work_order}')
            
            # 대시보드 데이터 조회
            dashboard = await client.get_dashboard()
            print(f'대시보드: {dashboard}')
            
        except Exception as error:
            print(f'오류 발생: {error}')


# 동기 버전 클라이언트
class SyncFacilityManagementClient:
    """동기 버전 시설 관리 시스템 API 클라이언트"""
    
    def __init__(self, base_url: str = 'https://api.qiro.com'):
        self.async_client = FacilityManagementClient(base_url)
        self.loop = None
    
    def __enter__(self):
        self.loop = asyncio.new_event_loop()
        asyncio.set_event_loop(self.loop)
        self.loop.run_until_complete(self.async_client.__aenter__())
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.loop:
            self.loop.run_until_complete(self.async_client.__aexit__(exc_type, exc_val, exc_tb))
            self.loop.close()
    
    def login(self, username: str, password: str) -> Dict[str, Any]:
        return self.loop.run_until_complete(self.async_client.login(username, password))
    
    def get_fault_reports(self, **options) -> Optional[Dict[str, Any]]:
        return self.loop.run_until_complete(self.async_client.get_fault_reports(**options))
    
    def create_fault_report(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        return self.loop.run_until_complete(self.async_client.create_fault_report(data))
    
    def get_work_orders(self, **options) -> Optional[Dict[str, Any]]:
        return self.loop.run_until_complete(self.async_client.get_work_orders(**options))
    
    def create_work_order(self, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        return self.loop.run_until_complete(self.async_client.create_work_order(data))
    
    def get_dashboard(self) -> Optional[Dict[str, Any]]:
        return self.loop.run_until_complete(self.async_client.get_dashboard())


# 동기 사용 예제
def sync_example():
    """동기 사용 예제"""
    with SyncFacilityManagementClient('https://api-dev.qiro.com') as client:
        try:
            # 로그인
            user = client.login('manager@example.com', 'password123')
            print(f'로그인 성공: {user}')
            
            # 고장 신고 목록 조회
            fault_reports = client.get_fault_reports(page=0, size=10)
            print(f'고장 신고 목록: {fault_reports}')
            
            # 대시보드 데이터 조회
            dashboard = client.get_dashboard()
            print(f'대시보드: {dashboard}')
            
        except Exception as error:
            print(f'오류 발생: {error}')


if __name__ == '__main__':
    # 비동기 예제 실행
    asyncio.run(example())
    
    # 동기 예제 실행
    # sync_example()
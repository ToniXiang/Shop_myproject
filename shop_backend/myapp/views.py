from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password
from django.core.cache import cache
from django.core.exceptions import ValidationError
from django.db import IntegrityError, DatabaseError
from rest_framework import status
import logging
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import ValidationError as DRFValidationError
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.authentication import JWTAuthentication
from .models import Product, Order
from .serializers import ProductSerializer, OrderSerializer, CreateOrderSerializer, CustomAuthTokenSerializer
import secrets
from typing import cast, Dict, Any

User = get_user_model()
logger = logging.getLogger(__name__)


class UserRegistrationView(APIView):
    """
    POST api/register/ - 存儲用戶的姓名、密碼、驗證碼和電子郵件
    """
    permission_classes = [AllowAny]

    def post(self, request):

        email = request.data.get('email')
        password = request.data.get('password')
        verification_code = request.data.get('verification_code')

        if not email or not password or not verification_code:
            return Response(
                {'message': '缺少必要參數'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        # 驗證電子郵件格式
        if email and ('@' not in email or '.' not in email.split('@')[-1]):
            return Response(
                {'message': '電子郵件格式錯誤'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        # 檢查密碼強度(至少8個字元，包含字母和數字)
        if password and (
                len(password) < 8 or not any(c.isalpha() for c in password) or not any(c.isdigit() for c in password)):
            return Response(
                {'message': '密碼強度不足，請至少包含8個字元，並包含字母和數字'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        # 驗證註冊驗證碼
        cached_code = cache.get(f'registration_{email}')
        if not cached_code:
            return Response(
                {'message': '驗證碼不存在或已過期，請重新發送'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        if cached_code != verification_code:
            return Response(
                {'message': '驗證碼錯誤'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        if User.objects.filter(email=email).exists():
            return Response(
                {'message': '此郵件已被註冊'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        try:
            User.objects.create_user(email=email, password=password, first_name=email.split('@')[0])
            cache.delete(f'registration_{email}')
            return Response(
                {'message': '註冊成功'},
                status=status.HTTP_201_CREATED,
                content_type='application/json; charset=utf-8'
            )
        except IntegrityError as e:
            logger.error(f"User registration integrity error: {str(e)}")
            return Response(
                {'message': '註冊失敗，用戶資料衝突'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            logger.error(f"User registration database error: {str(e)}")
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )


class UserLoginView(ObtainAuthToken):
    """
    POST api/login/ - 使用電子郵件和密碼進行驗證
    """
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = CustomAuthTokenSerializer(data=request.data, context={'request': request})
        if not serializer.is_valid():
            return Response(
                {'message': '電子郵件或密碼輸入錯誤'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        validated_data = cast(Dict[str, Any], serializer.validated_data)
        user = validated_data['user']
        refresh = RefreshToken.for_user(user)
        access_token = refresh.access_token

        return Response({
            'message': '登入成功',
            'access_token': str(access_token),
            'refresh_token': str(refresh),
            'email': user.email,
            'first_name': user.first_name
        }, status=status.HTTP_200_OK, content_type='application/json; charset=utf-8')


class ProductListView(APIView):
    """
    GET api/products/ - 獲取商品列表
    """
    permission_classes = [AllowAny]

    def get(self, request):

        try:
            products = Product.objects.all()
            serializer = ProductSerializer(products, many=True)
            return Response(
                {
                    "message": "商品列表取得成功",
                    "data": serializer.data
                },
                status=status.HTTP_200_OK,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            logger.error(f"Product list database error: {str(e)}")
            return Response(
                {
                    "message": "資料庫錯誤，請稍後再試",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )
        except DRFValidationError as e:
            logger.error(f"Product list serialization error: {str(e)}")
            return Response(
                {
                    "message": "資料序列化錯誤",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )


class OrderManagementView(APIView):
    """
    GET api/orders/ - 獲取用戶的訂單列表
    POST api/orders/ - 建立新訂單，需提供商品 ID 和數量
    DELETE api/orders/<int:order_id>/cancel/ - 取消訂單
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):

        try:
            orders = Order.objects.filter(user=request.user)
            serializer = OrderSerializer(orders, many=True)
            return Response(
                {
                    "message": "訂單列表取得成功",
                    "data": serializer.data
                },
                status=status.HTTP_200_OK,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            logger.error(f"Order list database error: {str(e)}")
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )
        except DRFValidationError as e:
            logger.error(f"Order list serialization error: {str(e)}")
            return Response(
                {'message': '資料序列化錯誤'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )

    def post(self, request):

        if not request.data or not any(request.data.values()):
            return Response(
                {
                    "message": "訂單建立失敗，沒有任何輸入資料",
                },
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        serializer = CreateOrderSerializer(data=request.data, context={'request': request})
        try:
            if serializer.is_valid():
                order = serializer.save(user=request.user)
                return Response(
                    {
                        "message": "訂單建立成功",
                        "data": OrderSerializer(order).data
                    },
                    status=status.HTTP_201_CREATED,
                    content_type='application/json; charset=utf-8'
                )
            return Response(
                {
                    "message": "訂單建立失敗，請確認輸入資料",
                    "errors": serializer.errors
                },
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )
        except IntegrityError as e:
            logger.error(f"Order creation integrity error: {str(e)}")
            return Response(
                {
                    "message": "訂單建立失敗，資料衝突",
                },
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            logger.error(f"Order creation database error: {str(e)}")
            return Response(
                {
                    "message": "資料庫錯誤，請稍後再試",
                },
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )
        except DRFValidationError as e:
            logger.error(f"Order creation validation error: {str(e)}")
            return Response(
                {
                    "message": "訂單資料驗證失敗",
                },
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

    def delete(self, request, order_id):

        try:
            order = Order.objects.get(id=order_id, user=request.user)
            order.delete()
            return Response(
                {'message': '訂單移除成功'},
                status=status.HTTP_200_OK,
                content_type='application/json; charset=utf-8'
            )
        except Order.DoesNotExist:
            return Response(
                {'message': '訂單不存在或無權限操作'},
                status=status.HTTP_404_NOT_FOUND,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            logger.error(f"Order deletion database error: {str(e)}")
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )


class UserProfileView(APIView):
    """
    GET api/user/info - 獲取用戶的姓名和電子郵件
    PUT api/user/update_name/ - 更新用戶的姓名，需提供新的姓名
    """
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):

        try:
            user = request.user
            if user.is_authenticated:
                data = {
                    "first_name": getattr(user, 'first_name', ''),
                    "email": getattr(user, 'email', '')
                }
                return Response(
                    {
                        "message": "用戶資料取得成功",
                        "data": data
                    },
                    status=status.HTTP_200_OK,
                    content_type='application/json; charset=utf-8'
                )
            else:
                return Response(
                    {'message': '使用者未登入'},
                    status=status.HTTP_401_UNAUTHORIZED,
                    content_type='application/json; charset=utf-8'
                )
        except DatabaseError as e:
            logger.error(f"User profile database error: {str(e)}")
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )

    def put(self, request):
        user = request.user
        new_name = request.data.get('name')
        if not new_name:
            return Response(
                {'message': '缺少新的使用者名稱'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )
        if len(new_name.strip()) < 2:
            return Response(
                {'error': 'Name must be at least 2 characters'},
                status=status.HTTP_400_BAD_REQUEST
            )
        user.first_name = new_name
        user.save()
        return Response(
            {'message': '使用者名稱更新成功'},
            status=status.HTTP_200_OK,
            content_type='application/json; charset=utf-8'
        )


class SendVerificationCodeView(APIView):
    """
    POST api/send_verification_code/ - 發送驗證碼，需提供電子郵件和用途（registration 或 password_reset）
    驗證碼為 6 位數字，存儲在緩存中，5 分鐘有效
    """
    permission_classes = [AllowAny]

    def post(self, request):

        email = request.data.get('email')
        purpose = request.data.get('purpose')

        if not email or not purpose or purpose not in ['registration', 'password_reset']:
            return Response(
                {'message': '缺少必要參數或參數值錯誤'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        try:
            verification_code = f"{secrets.randbelow(1_000_000):06d}"
            if (purpose == 'registration'):
                cache.set(f'registration_{email}', verification_code, timeout=300)  # 5 分鐘有效
            else:
                cache.set(f'password_reset_{email}', verification_code, timeout=300)  # 5 分鐘有效

            # TODO: 用郵件發送驗證碼
            print(f'驗證碼發送到 {email}: {verification_code} 用於 {purpose}')

            return Response(
                {'message': '驗證碼已發送'},
                status=status.HTTP_200_OK,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError as e:
            logger.error(f"Verification code database error: {str(e)}")
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )


class PasswordResetView(APIView):
    """
    POST api/reset_password/ - 重設密碼，需提供電子郵件、驗證碼和新密碼
    """
    permission_classes = [AllowAny]

    def post(self, request):

        email = request.data.get('email')
        code = request.data.get('code')
        new_password = request.data.get('password')

        if not all([email, code, new_password]):
            return Response(
                {'message': '缺少必要參數'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        # 檢查密碼強度
        if len(new_password) < 8 or not any(c.isalpha() for c in new_password) or not any(
                c.isdigit() for c in new_password):
            return Response(
                {'message': '密碼強度不足，請至少包含8個字元，並包含字母和數字'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        cached_code = cache.get(f'password_reset_{email}')
        if cached_code != code:
            return Response(
                {'message': '驗證碼錯誤或已過期'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

        try:
            user = User.objects.get(email=email)
            user.password = make_password(new_password)
            user.save()
            cache.delete(f'password_reset_{email}')
            return Response(
                {'message': '密碼重設成功'},
                status=status.HTTP_200_OK,
                content_type='application/json; charset=utf-8'
            )
        except User.DoesNotExist:
            return Response(
                {'message': '用戶不存在'},
                status=status.HTTP_404_NOT_FOUND,
                content_type='application/json; charset=utf-8'
            )
        except DatabaseError:
            return Response(
                {'message': '資料庫錯誤，請稍後再試'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
                content_type='application/json; charset=utf-8'
            )
        except ValidationError:
            return Response(
                {'message': '密碼格式不正確'},
                status=status.HTTP_400_BAD_REQUEST,
                content_type='application/json; charset=utf-8'
            )

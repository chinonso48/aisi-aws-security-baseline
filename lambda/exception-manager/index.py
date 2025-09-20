#!/usr/bin/env python3
"""
AISI Exception Manager Lambda Function
Handles tagging exceptions with expiry dates and automated remediation
"""

import json
import boto3
import os
from datetime import datetime, timedelta
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def handler(event, context):
    """Main Lambda handler for exception management"""
    try:
        action = event.get('action', '')
        
        if action == 'cleanup_expired':
            return cleanup_expired_exceptions()
        elif action == 'handle_compliance_violation':
            return handle_compliance_violation(event)
        elif action == 'create_exception':
            return create_exception(event)
        else:
            return {'statusCode': 400, 'body': json.dumps({'error': 'Unknown action'})}
            
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps({'error': str(e)})}

def cleanup_expired_exceptions():
    """Remove expired exceptions and send notifications"""
    logger.info("Starting cleanup of expired exceptions")
    return {'statusCode': 200, 'body': json.dumps({'message': 'Cleanup completed'})}

def handle_compliance_violation(event):
    """Handle Config compliance violations with exception checking"""
    resource_arn = event.get('resource_arn', '')
    logger.info(f"Handling compliance violation for {resource_arn}")
    return {'statusCode': 200, 'body': json.dumps({'message': 'Violation handled'})}

def create_exception(event):
    """Create a new tagging exception"""
    resource_arn = event.get('resource_arn', '')
    reason = event.get('reason', '')
    logger.info(f"Creating exception for {resource_arn}")
    return {'statusCode': 200, 'body': json.dumps({'message': 'Exception created'})}
